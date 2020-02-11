import urllib.request, json
import networkx as nx
import matplotlib.pyplot as plt
import sys

def post2node(addr, method):
    url = "http://"+ addr + ":8545" 
    headers = {"Content-Type" : "application/json"}

    obj = {"jsonrpc":"2.0","method":method,"params":[],"id":67}
    json_data = json.dumps(obj).encode("utf-8")

    request = urllib.request.Request(url, data=json_data, method="POST", headers=headers)
    with urllib.request.urlopen(request) as response:
        response_body = response.read().decode("utf-8")
    return response_body

def get_peerlist(addr):
    res = json.loads(post2node(addr, "admin_peers"))
    peernum = len(res["result"])
    peers = []
    for i in range(peernum):
        peers.append(res["result"][i]["network"]["remoteAddress"].split(":")[0])
    return peers

def addNodesToGraph(graph, initial, checked=[]):
    # initalize node
    checked.append(initial)
    graph.add_node(initial)
    
    # get peer list
    print("Get nodes from %s" %initial)
    peerlist = get_peerlist(initial)
    print("Num of Peer on %s: %s" %(initial, len(peerlist),))
    
    # add to graph
    for peer in peerlist:
        graph.add_edge(initial, peer)
        if peer not in checked:
            graph, checked = addNodesToGraph(graph, peer, checked)
    return graph, checked

def get_blockheight(node):
    res = json.loads(post2node(node, "eth_blockNumber"))
    blockheight = int(res["result"][2:], 16)
    return blockheight

if __name__ == '__main__':
    args = sys.argv
    node = "172.18.0.2"
    graph = nx.Graph()
    graph, nodelist = addNodesToGraph(graph, node)
    blockheightlist = [get_blockheight(addr) for addr in graph.nodes()]
    print(blockheightlist)

    nx.draw(graph, node_color = blockheightlist, with_labels = True)
    plt.savefig("/root/graph/"+args[1]+".png", bbox_inches='tight')
