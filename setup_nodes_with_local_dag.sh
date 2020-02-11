#!/bin/bash
INT=10
TESTDIR=$(pwd)
DATE=$(date "+%Y%m%d-%H%M%S")
UNITDIR=$TESTDIR/result/$DATE
NODENUM=$1
GETHOPTION=$2

# For Gnu-sed on MacOS
if [ "$(uname)" == 'Darwin' ]; then
    shopt -s expand_aliases
    alias sed="gsed"
fi

. src/launch_node_with_local_dag.sh

function exec_on_node(){
    # $1 node ID
    # $2 Exec parameters
    docker exec -i $DATE-node$1 sh -c 'echo "'$2'" | geth attach' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2};5D)?)?[mGK]//g" | tail -n +10 | sed -e '$d'
}

function get_enode(){ 
    # $1 node id
    NODE1_ENODE=$(exec_on_node $1 "admin.nodeInfo" | grep enode | tr -d "\" "| sed "s/@.*/@/g" | tail -c +7)
    NODE1_IP=$(docker inspect --format '{{ .NetworkSettings.Networks.internalnet.IPAddress }}' $DATE-node$1)
    echo $NODE1_ENODE$NODE1_IP":30303"
}

mkdir $UNITDIR

echo "Run Node1 as BootNode"
LaunchNode 001 "$GETHOPTION"

# Get Node1 enode
NODE1=$(get_enode 001)
echo "Node1 Enode: "$NODE1

for i in $(seq -f '%03g' 2 $NODENUM);
do
    LaunchNode $i "$GETHOPTION"
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
