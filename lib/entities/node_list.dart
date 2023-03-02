import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import "package:yaml/yaml.dart";
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';


Future<List<Node>> loadDefaultNodes(NetworkKind network) async {
  final nodesRaw = await rootBundle.loadString('assets/monero_node_list_${network.name}.yml');
  final YamlList? loadedNodes;
  if (nodesRaw!=null) {
    var loadYaml2 = loadYaml(nodesRaw);
    loadedNodes = loadYaml2==null?null:loadYaml2 as YamlList;
  } else {
    loadedNodes = null;
  }
  final nodes = <Node>[];
  if(loadedNodes!=null)
    for (final raw in loadedNodes) {
      if (raw is Map) {
        final node = Node.fromMap(Map<String, Object>.from(raw));
        node.type = WalletType.monero;
        nodes.add(node);
      }
    }

  return nodes;
}

Future<List<Node>> loadBitcoinElectrumServerList(NetworkKind network) async {
  final serverListRaw =
      await rootBundle.loadString('assets/bitcoin_electrum_server_list_${network.name}.yml');
  final loadedServerList0 = loadYaml(serverListRaw);
  final loadedServerList = loadedServerList0==null?null:loadedServerList0 as YamlList;
  final serverList = <Node>[];

  if(loadedServerList!=null)
    for (final raw in loadedServerList) {
     if (raw is Map) {
        final node = Node.fromMap(Map<String, Object>.from(raw));
        node.type = WalletType.bitcoin;
        serverList.add(node);
      }
    }

  return serverList;
}

Future<List<Node>> loadLitecoinElectrumServerList(NetworkKind network) async {
  final serverListRaw =
      await rootBundle.loadString('assets/litecoin_electrum_server_list_${network.name}.yml');
  var loadYaml2 = loadYaml(serverListRaw);
  final loadedServerList = loadYaml2==null?[]:loadYaml2 as YamlList;
  final serverList = <Node>[];

  for (final raw in loadedServerList) {
    if (raw is Map) {
      final node = Node.fromMap(Map<String, Object>.from(raw));
      node.type = WalletType.litecoin;
      serverList.add(node);
    }
  }

  return serverList;
}

Future<List<Node>> loadDefaultHavenNodes(NetworkKind network) async {
  final nodesRaw = await rootBundle.loadString('assets/haven_node_list_${network.name}.yml');
  var loadYaml2 = loadYaml(nodesRaw);
  final loadedNodes = loadYaml2==null?[]:loadYaml2 as YamlList;
  final nodes = <Node>[];

  for (final raw in loadedNodes) {
    if (raw is Map) {
      final node = Node.fromMap(Map<String, Object>.from(raw));
      node.type = WalletType.haven;
      nodes.add(node);
    }
  }
  
  return nodes;
}

Future resetToDefault(Box<Node> nodeSourceMainnet, Box<Node> nodeSourceTestnet) async {
  resetToDefault0(nodeSourceMainnet, NetworkKind.mainnet);
  resetToDefault0(nodeSourceTestnet, NetworkKind.testnet);
}

Future resetToDefault0(Box<Node> nodeSource, NetworkKind network) async {
  final moneroNodes = await loadDefaultNodes(network);
  final bitcoinElectrumServerList = await loadBitcoinElectrumServerList(network);
  final litecoinElectrumServerList = await loadLitecoinElectrumServerList(network);
  final havenNodes = await loadDefaultHavenNodes(network);
  final nodes =
      moneroNodes +
      bitcoinElectrumServerList +
      litecoinElectrumServerList +
      havenNodes;

  await nodeSource.clear();
  await nodeSource.addAll(nodes);
}
