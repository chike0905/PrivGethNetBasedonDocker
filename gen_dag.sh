#!/bin/bash

TESTDIR=$(pwd)
# Generate dag in scripts/ethash
GETHFORSETUP="docker run --rm --net internalnet --name setup -v "$TESTDIR"/scripts/ethash:/root/.ethash ethereum/client-go:v1.9.10 --nousb"

$GETHFORSETUP makedag 0 /root/.ethash
