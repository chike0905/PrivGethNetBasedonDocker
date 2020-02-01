# Ethereum Privare Network on Docker
## Motivation & Overview
When we develop an application that based on Ethereum, we want to test not only on a single node but also on a network. The scripts create Ethereum private network based on Docker. With an internal docker network, you can test without affected by other nodes on the Internet.

## Enviroment
- Docker
    - Image: ethereum/client-go:v1.9.10
## How to Use
### Contents
```
.
├── result                        : result directory
├── scripts
│   ├── get_blocknum.js
│   ├── get_enode.js
│   ├── get_peers.js
│   ├── password
│   └── privnet.json              : Private Network params
├── setup_nodes.sh                : setup nodes script
└── stop_nodes.sh                 : stop nodes script

```
### Set Up Docker Container & Network
- Pull the container image of geth.
```
docker pull ethereum/client-go:v1.9.10
```
- Create docker internal network.
```
docker network create --driver=bridge --internal internalnet
```
### Launch Nodes
- Run `setup_nodes.sh` with setupping number of Nodes for test.
    - **Note:** You should check other docker containers on your host. The `stop_node.sh` kills the all node on your host.
```sh
./setup_nodes.sh $NODENUM
```
- In the end of running `setup_nodes.sh`, the script dumps the directory of the test.
### Stop Nodes
- Run `stop_node.sh` with the directory path that dumped the end of `setup_nodes.sh`.
```
./stop_node.sh /the/path/that/dumped/by/setup/script
```
### Dumped Files
- `setup_nodes.sh` create a test directory to store test logs.
    - The name of the test directory is `YYYYmmdd-HHMMSS`.
    - The contents are as like followings;
        - Data directory of node1 has ethereum and ethash for mining.
        - Data directory of other node is just only as ethereum datadir.
    ```
    result/20200101-0000000/
    ├── logs            : geth log on each node
    │   ├── node1
    │   ├── node2
    │   └── node3
    ├── node1           : Datadir for node1
    │   ├── ethereum    : Ethereum Datadir
    │   └── ethash      : Ethash Dir
    ├── node2           : Ethereum datadir for node2
    ...
    └── node3    : for node3
    ```

## ToDo
- How to make topology?
    - (Temporary) Nodes connect to Node1.
- How to mining?
    - (Temporary) Node 1 is mining.
## Licence
WTFPL