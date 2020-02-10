#! /bin/bash
INT=10
TESTDIR=$(pwd)
DATE=$(date "+%Y%m%d-%H%M%S")
UNITDIR=$TESTDIR/result/$DATE
NODENUM=$1

function LaunchNode(){
    # $1 Node ID
    # $2 options for geth
    mkdir $UNITDIR/node$1
    mkdir $UNITDIR/node$1/ethereum
    mkdir $UNITDIR/node$1/ethash
    
    # Setup Mining
    GETHFORSETUP="docker run --rm --net internalnet --name setup -v "$UNITDIR"/node"$1"/ethereum:/root/.ethereum -v "$UNITDIR"/node"$1"/ethash:/root/.ethash -v "$TESTDIR"/scripts:/root/scripts ethereum/client-go:v1.9.10 --nousb"
    
    ## Copy from pre-generated dag since making dag time is too long
    # TODO: tmp copy from node001
    if [ $1 = "001" ]; then
        $GETHFORSETUP makedag 0 /root/.ethash
    else
        cp $UNITDIR/node001/ethash/full-R23-0000000000000000 $UNITDIR/node$1/ethash/
    fi
    
    $GETHFORSETUP init /root/scripts/privnet.json
    $GETHFORSETUP account new --password /root/scripts/password
    
    # Launch Node
    docker run -d --net internalnet --name $DATE-node$1 -v $UNITDIR/node$1/ethereum:/root/.ethereum -v $UNITDIR/node$1/ethash:/root/.ethash -v $TESTDIR/scripts:/root/scripts ethereum/client-go:v1.9.10 --networkid 114514 --verbosity 4 --syncmode "full" --nousb $2 
    echo "Sleep "$INT" seconds for launch node"$1
    sleep $INT
}


function exec_on_node(){
    # $1 node ID
    # $2 Exec parameters
    docker exec -it $DATE-node$1 sh -c 'echo "'$2'" | geth attach' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2};5D)?)?[mGK]//g" | tail -n +10 | sed -e '$d'
}

function get_enode(){ 
    # $1 node id
    NODE1_ENODE=$(exec_on_node $1 "admin.nodeInfo" | grep enode | tr -d "\" "| sed "s/@.*/@/g" | tail -c +7)
    NODE1_IP=$(docker inspect --format '{{ .NetworkSettings.Networks.internalnet.IPAddress }}' $DATE-node$1)
    echo $NODE1_ENODE$NODE1_IP":30303"
}

mkdir $UNITDIR

echo "Run Node1 as BootNode"
LaunchNode 001

# Get Node1 enode
NODE1=$(get_enode 001)
echo "Node1 Enode: "$NODE1

for i in $(seq -f '%03g' 2 $NODENUM);
do
    LaunchNode $i
done

# TMP: all node connect to node 001
for i in $(seq -f '%03g' 2 $NODENUM);
do
    exec_on_node $i "admin.addPeer('"$NODE1"')"
done

echo "waiting discover each nodes...("$INT" seconds)"
sleep $INT

# Dump peers of all node
for i in $(seq -f '%03g' 1 $NODENUM);
do
    echo "Peers of Node"$i":"
    exec_on_node $i "admin.peers"
done

echo "Nodes started on " $UNITDIR
echo "UNIT_NAME: "$DATE
