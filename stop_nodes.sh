#! /bin/bash
UNITDIR=$1
NODENAME=$(docker ps --format "table {{.Names}}" | tail -n +2)
echo "Stop Containers"
for i in $NODENAME
do
    docker stop $i
done

echo "Dumping Logs"
NODENAME=$(docker ps -a --format "table {{.Names}}" | tail -n +2)
mkdir $UNITDIR/logs
for i in $NODENAME
do
    docker logs $i 2> $UNITDIR/logs/$i
done

echo "Remove Containers"
for i in $NODENAME
do
    docker rm $i
done
