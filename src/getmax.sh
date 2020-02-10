#!/bin/bash

function getMaxNodeIdInTopology(){
    # $1 topology file
    # TODO: How to manage large topology file?(memory issue)
    TOPOFILE=$1
    
    dists=$(cat $TOPOFILE | awk '{print $2}' | sed 's/0*\([0-9]*[0-9]$\)/\1/g')
    srcs=$(cat $TOPOFILE | awk '{print $1}' | sed 's/0*\([0-9]*[0-9]$\)/\1/g')
    distmax=$(getmax "$dists")
    srcmax=$(getmax "$srcs")
    max=$(getmax "$distmax $srcmax")
    echo $max
}

function getmax(){
  # $1 list of number
    tmpmax=0
    for i in $1
    do
        if [ $i -gt $tmpmax ];then
            tmpmax=$i
        fi
    done
    echo $tmpmax
}
