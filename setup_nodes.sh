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
    docker run -d --net internalnet --name $DATE-node$1 -v $UNITDIR/node$1/ethereum:/root/.ethereum -v $UNITDIR/node$1/ethash:/root/.ethash -v $TESTDIR/scripts:/root/scripts ethereum/client-go:v1.9.10 --networkid 114514 --verbosity 4 --syncmode "full" --mine --miner.threads 10 -bootnodes $2
    echo "Sleep "$INT" seconds for launch node"$1
    sleep $INT
}

function exec_on_node(){
    # $1 node ID
    # $2 Exec parameters
    docker exec -it $DATE-node$1 sh -c 'echo "'$2'" | geth attach' | gsed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2};5D)?)?[mGK]//g" | tail -n +10 | gsed -e '$d'
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
echo "" > $TESTDIR/scripts/password
$GETHFORSETUP account new --password /root/scripts/password

docker run -d --net internalnet --name $DATE-node001 -v $UNITDIR/node1/ethereum:/root/.ethereum -v $UNITDIR/node1/ethash:/root/.ethash -v $TESTDIR/scripts:/root/scripts ethereum/client-go:v1.9.10 --networkid 114514 --verbosity 4 --syncmode "full" --mine --miner.threads 10
echo "Sleep "$INT" seconds for launch BootNode(Node1)"
sleep $INT


# Get Node1 enode
NODE1_ENODE=$(exec_on_node 001 "admin.nodeInfo" | grep enode | tr -d "\" "| sed "s/@.*/@/g" | tail -c +7)
NODE1_IP=$(docker inspect --format '{{ .NetworkSettings.Networks.internalnet.IPAddress }}' $DATE-node001)
NODE1=$NODE1_ENODE$NODE1_IP:30303
echo "Node1 Enode: "$NODE1

for i in $(seq -f '%03g' 2 $NODENUM);
do
    launchnode $i $NODE1
done

echo "waiting discover each nodes...("$INT" seconds)"
sleep $INT

exec_on_node 001 "admin.peers"
exec_on_node 002 "admin.peers"

echo "Nodes started on " $UNITDIR
echo "UNIT_NAME: "$DATE
