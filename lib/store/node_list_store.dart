import 'dart:async';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/utils/mobx.dart';

part 'node_list_store.g.dart';

class NodeListStoreMainnet = NodeListStoreBase with _$NodeListStore;
class NodeListStoreTestnet = NodeListStoreBase with _$NodeListStore;

abstract class NodeListStoreBase with Store {
  NodeListStoreBase() : nodesMainnet = ObservableList<Node>(), nodesTestnet = ObservableList<Node>();

  static StreamSubscription<BoxEvent>? _onNodesSourceChangeMainnet;
  static StreamSubscription<BoxEvent>? _onNodesSourceChangeTestnet;
  static NodeListStoreMainnet? _instanceMainnet;
  static NodeListStoreTestnet? _instanceTestnet;

  static void init(Box<Node> nodeSourceMainnet, Box<Node> nodeSourceTestnet) {
    _instanceMainnet = NodeListStoreMainnet();
    _instanceMainnet!.nodesMainnet.clear();
    _instanceMainnet!.nodesMainnet.addAll(nodeSourceMainnet.values);
    _instanceMainnet!.nodesTestnet.clear();
    _instanceMainnet!.nodesTestnet.addAll(nodeSourceTestnet.values);
    _onNodesSourceChangeMainnet?.cancel();
    _onNodesSourceChangeMainnet = nodeSourceMainnet.bindToList(_instanceMainnet!.nodesMainnet);

    _instanceTestnet = NodeListStoreTestnet();
    _instanceTestnet!.nodesMainnet.clear();
    _instanceTestnet!.nodesMainnet.addAll(nodeSourceMainnet.values);
    _instanceTestnet!.nodesTestnet.clear();
    _instanceTestnet!.nodesTestnet.addAll(nodeSourceTestnet.values);
    _onNodesSourceChangeTestnet?.cancel();
    _onNodesSourceChangeTestnet = nodeSourceMainnet.bindToList(_instanceTestnet!.nodesTestnet);
  }

  static NodeListStoreMainnet get instanceMainnet {
    return _instanceMainnet!;
  }

  static NodeListStoreTestnet get instanceTestnet {
    return _instanceTestnet!;
  }

  final ObservableList<Node> nodesMainnet;
  final ObservableList<Node> nodesTestnet;
}
