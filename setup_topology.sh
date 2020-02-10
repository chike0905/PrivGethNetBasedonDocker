#!/bin/bash
INT=10
TESTDIR=$(pwd)
DATE=$(date "+%Y%m%d-%H%M%S")
UNITDIR=$TESTDIR/result/$DATE
TOPOFILE=$1

# For Gnu-sed on MacOS
if [ "$(uname)" == 'Darwin' ]; then
    shopt -s expand_aliases
    alias sed="gsed"
fi

. src/launch_node_with_local_dag.sh

# Get Max Node ID in topology File
. src/getmax.sh
NODENUM=$(getMaxNodeIdInTopology $1)

function exec_on_node(){
    # $1 node ID
    # $2 Exec parameters
    docker exec -i $DATE-node$1 sh -c 'echo "'$2'" | geth attach' | gsed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2};5D)?)?[mGK]//g" | tail -n +10 | gsed -e '$d'
}

function get_enode(){ 
    # $1 node id
    NODE1_ENODE=$(exec_on_node $1 "admin.nodeInfo" | grep enode | tr -d "\" "| sed "s/@.*/@/g" | tail -c +7)
    NODE1_IP=$(docker inspect --format '{{ .NetworkSettings.Networks.internalnet.IPAddress }}' $DATE-node$1)
    echo $NODE1_ENODE$NODE1_IP":30303"
}

function make_connection(){
    # $1 connection params
    source=$1
    dist=$2
    echo "Make Connection to "$dist" from "$source
    enode=$(get_enode $dist)
    echo $enode
    exec_on_node $source "admin.addPeer('"$enode"')"
}

function make_topology(){
    # $1 topology file
    # TODO: How to manage large topology file?(memory issue)
    TOPOFILE=$1
    FILE=$(cat $TOPOFILE)
    PREV_IFS=$IFS
    IFS=$'\n'
    for line in $FILE;
    do
      IFS=$PREV_IFS
      make_connection $line 
    done
    echo "waiting discover each nodes...("$INT" seconds)"
    sleep $INT
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

make_topology $TOPOFILE

# Dump peers of all node
for i in $(seq -f '%03g' 1 $NODENUM);
do
    echo "Peers of Node"$i":"
    exec_on_node $i "admin.peers"
done

echo "Nodes started on " $UNITDIR
echo "UNIT_NAME: "$DATE
