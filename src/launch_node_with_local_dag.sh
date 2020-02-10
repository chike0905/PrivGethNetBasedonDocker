#! /bin/bash
function LaunchNode(){
    # $1 Node ID
    # $2 options for geth
    mkdir $UNITDIR/node$1
    mkdir $UNITDIR/node$1/ethereum
    mkdir $UNITDIR/node$1/ethash
    
    # Setup Mining
    GETHFORSETUP="docker run --rm --net internalnet --name setup -v "$UNITDIR"/node"$1"/ethereum:/root/.ethereum -v "$UNITDIR"/node"$1"/ethash:/root/.ethash -v "$TESTDIR"/scripts:/root/scripts ethereum/client-go:v1.9.10 --nousb"
    
    ## Copy from pre-generated dag since making dag time is too long
    cp $TESTDIR/scripts/ethash/full-R23-0000000000000000 $UNITDIR/node$1/ethash/
    
    $GETHFORSETUP init /root/scripts/privnet.json
    $GETHFORSETUP account new --password /root/scripts/password
    
    # Launch Node
    docker run -d --net internalnet --name $DATE-node$1 -v $UNITDIR/node$1/ethereum:/root/.ethereum -v $UNITDIR/node$1/ethash:/root/.ethash -v $TESTDIR/scripts:/root/scripts ethereum/client-go:v1.9.10 --networkid 114514 --verbosity 4 --syncmode "full" --nousb $2 
    echo "Sleep "$INT" seconds for launch node"$1
    sleep $INT
}
