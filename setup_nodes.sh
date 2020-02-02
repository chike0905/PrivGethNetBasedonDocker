#! /bin/bash
INT=10
TESTDIR=$(pwd)
DATE=$(date "+%Y%m%d-%H%M%S")
UNITDIR=$TESTDIR/result/$DATE
NODENUM=$1

function launchnode(){
    # $1 nodennum
    # $2 bootnode enode
    mkdir $UNITDIR/node$1
    mkdir $UNITDIR/node$1/ethereum
    mkdir $UNITDIR/node$1/ethash
    
    # Setup Mining
    # TODO: tmp copy from node1
    cp $UNITDIR/node1/ethash/full-R23-0000000000000000 $UNITDIR/node$1/ethash/
    GETHFORSETUP="docker run --rm --net internalnet --name setup -v "$UNITDIR"/node"$1"/ethereum:/root/.ethereum -v "$UNITDIR"/node"$1"/ethash:/root/.ethash -v "$TESTDIR"/scripts:/root/scripts ethereum/client-go:v1.9.10"
    $GETHFORSETUP init /root/scripts/privnet.json
    $GETHFORSETUP account new --password /root/scripts/password
    
    # Launch Node
    docker run -d --net internalnet --name node$1 -v $UNITDIR/node$1/ethereum:/root/.ethereum -v $UNITDIR/node$1/ethash:/root/.ethash -v $TESTDIR/scripts:/root/scripts ethereum/client-go:v1.9.10 --networkid 114514 --verbosity 4 --syncmode "full" --mine --miner.threads 10 -bootnodes $2
    echo "Sleep "$INT" seconds for launch node"$1
    sleep $INT
}

function checkpeer(){
    # $1 node ID
    echo "Check Peer of Node"$1
    docker exec -it node$1 sh -c "geth attach < /root/scripts/get_peers.js"
}

function checkblocknum(){
    # $1 node ID
    echo "Check BlockNumber of Node"$1
    docker exec -it node$1 sh -c "geth attach < /root/scripts/get_blocknum.js" | tail -n 2 | head -n 1
}


mkdir $UNITDIR

echo "Run Node1 as BootNode"
mkdir $UNITDIR/node1
mkdir $UNITDIR/node1/ethereum
mkdir $UNITDIR/node1/ethash

GETHFORSETUP="docker run --rm --net internalnet --name setup -v "$UNITDIR"/node1/ethereum:/root/.ethereum -v "$UNITDIR"/node1/ethash:/root/.ethash -v "$TESTDIR"/scripts:/root/scripts ethereum/client-go:v1.9.10"
$GETHFORSETUP init /root/scripts/privnet.json

## prepare mining
## TODO: make dag time is too long
$GETHFORSETUP makedag 0 /root/.ethash
#cp scripts/full-R23-0000000000000000 $UNITDIR/node1/ethash/
echo "" > $TESTDIR/scripts/password
$GETHFORSETUP account new --password /root/scripts/password

docker run -d --net internalnet --name node1 -v $UNITDIR/node1/ethereum:/root/.ethereum -v $UNITDIR/node1/ethash:/root/.ethash -v $TESTDIR/scripts:/root/scripts ethereum/client-go:v1.9.10 --networkid 114514 --verbosity 4 --syncmode "full" --mine --miner.threads 10
echo "Sleep "$INT" seconds for launch BootNode(Node1)"
sleep $INT


# Get Node1 enode
NODE1_ENODE=$(docker exec -it node1 sh -c "geth attach < /root/scripts/get_enode.js" | grep enode | tr -d "\""| sed "s/@.*/@/g" | gsed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
NODE1_IP=$(docker inspect --format '{{ .NetworkSettings.Networks.internalnet.IPAddress }}' node1)
NODE1=$NODE1_ENODE$NODE1_IP:30303
echo "Node1 enode: "$NODE1

for i in $(seq 2 $NODENUM)
do
    launchnode $i $NODE1
done

echo "waiting discover each nodes...("$INT" seconds)"
sleep $INT

echo "Check Peers"
for i in $(seq 1 $NODENUM)
do
    checkpeer $i 
done

<<COMMENTOUT
echo "Check BlockNum"
for i in $(seq 1 $NODENUM)
do
    checkblocknum $i 
done
COMMENTOUT
echo "Nodes started on " $UNITDIR
