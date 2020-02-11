#!/bin/bash
TIMES=$1
for i in $(seq -f '%03g' $TIMES);
do
    docker run --rm -it --net internalnet -v $(pwd)/graph:/root/graph visualizer $i
    sleep 1
done
