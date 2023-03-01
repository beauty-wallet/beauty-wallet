import 'dart:async';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/utils/mobx.dart';

part 'node_list_store.g.dart';

class NodeListStore = NodeListStoreBase with _$NodeListStore;

abstract class NodeListStoreBase with Store {
  NodeListStoreBase() : nodesMainnet = ObservableList<Node>(), nodesTestnet = ObservableList<Node>();

  static StreamSubscription<BoxEvent>? _onNodesSourceChangeMainnet;
  static StreamSubscription<BoxEvent>? _onNodesSourceChangeTestnet;
  static NodeListStore? _instance;

  static NodeListStore get instance {
    if (_instance != null) {
      return _instance!;
    }

    final nodeSourceMainnet = getIt.get<NodeListViewModelMainnet>().getNodeSourceMainnet();
    final nodeSourceTestnet = getIt.get<NodeListViewModelTestnet>().getNodeSourceTestnet();
    _instance = NodeListStore();
    _instance!.nodesMainnet.clear();
    _instance!.nodesMainnet.addAll(nodeSourceMainnet.values);
    _instance!.nodesTestnet.clear();
    _instance!.nodesTestnet.addAll(nodeSourceTestnet.values);
    _onNodesSourceChangeMainnet?.cancel();
    _onNodesSourceChangeMainnet = nodeSourceMainnet.bindToList(_instance!.nodesMainnet);

    return _instance!;
  }

  final ObservableList<Node> nodesMainnet;
  final ObservableList<Node> nodesTestnet;
}
