Priv Net Visualizer
==
## Overview
- Visualize Private Network
  - via Python3.7(NewtworkX) 

## Enviroment
- docker
  - debian

## Usage
- Build `Dockerfile`
```
docker build -t visualizer:latest .
```
- Launch topology with rpc api.
```
./setup_topology.sh sample_topology.txt "-rpc --rpcapi admin,eth --rpcaddr 0.0.0.0"
```
- Run container with mounting `graph` dir.
  - You can get a png file that is the visualized topology.
  - optional: you can set the filenname of visualized topology at the end of following command(default `graph`).
```
docker run --rm -it --net internalnet -v $(pwd)/graph:/root/graph visualizer:latest
```

## ToDo
- How parameter should be visualized?
