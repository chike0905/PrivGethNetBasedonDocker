#! /bin/bash
UNIT=$1
UNITDIR=result/$UNIT
NODENAME=$(docker ps --format "table {{.Names}}" | tail -n +2 | grep $UNIT)
echo "Stop Containers"
for i in $NODENAME
do
    docker stop $i
done

echo "Dumping Logs"
mkdir $UNITDIR/logs
for i in $NODENAME
do
    docker logs $i 2> $UNITDIR/logs/$i
done

echo "Waiting shutdown containers...(10 seconds)"
sleep 10

echo "Remove Containers"
for i in $NODENAME
do
    docker rm $i
done

echo "Merge Logs"
python scripts/merge_logs.py $UNITDIR
