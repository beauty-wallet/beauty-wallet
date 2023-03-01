import 'package:cake_wallet/generated/i18n.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/utils/mobx.dart';

part 'node_list_view_model.g.dart';

class NodeListViewModelMainnet = NodeListViewModelBase with _$NodeListViewModelMainnet;
class NodeListViewModelTestnet = NodeListViewModelBase with _$NodeListViewModelMainnet;

enum NetworkKind {mainnet, testnet}

abstract class NodeListViewModelBase with Store {
  NodeListViewModelBase(this.network, this._nodeSourceMainnet, this._nodeSourceTestnet, this.wallet, this.settingsStore)
      : nodesMainnet = ObservableList<Node>(), nodesTestnet = ObservableList<Node>() {
    _nodeSourceMainnet.bindToList(nodesMainnet,
        filter: (Node val) => val?.type == wallet.type, initialFire: true);
    _nodeSourceTestnet.bindToList(nodesTestnet,
          filter: (Node val) => val?.type == wallet.type, initialFire: true);
  }

  final NetworkKind network;

  @computed
  Node get currentNode {
    final node = network == NetworkKind.mainnet ? settingsStore.nodesMainnet[wallet.type] : settingsStore.nodesTestnet[wallet.type];

    if (node == null) {
      throw Exception('No node for wallet type: ${wallet.type}');
    }

    return node;
  }

  String getAlertContent(String uri) =>
      S.current.change_current_node(uri) +
          '${uri.endsWith('.onion') || uri.contains('.onion:') ? '\n' + S.current.orbot_running_alert : ''}';

  final ObservableList<Node> nodesMainnet;
  final ObservableList<Node> nodesTestnet;
  final SettingsStore settingsStore;
  final WalletBase wallet;
  final Box<Node> _nodeSourceMainnet;
  final Box<Node> _nodeSourceTestnet;
  Box<Node> getNodeSourceMainnet() {
    return _nodeSourceMainnet;
  }
  Box<Node> getNodeSourceTestnet() {
    return _nodeSourceTestnet;
  }

  Box<Node> getNodeSource() {
    if(network==NetworkKind.mainnet)
      return _nodeSourceMainnet;
    else
      return _nodeSourceTestnet;
  }

  Future<void> reset() async {
    await resetToDefault(_nodeSourceMainnet, _nodeSourceTestnet);

    Node? node;

    switch (wallet.type) {
      case WalletType.bitcoin:
        node = getBitcoinDefaultElectrumServer(nodes: getNodeSource())!;
        break;
      case WalletType.monero:
        node = getMoneroDefaultNode(nodes: getNodeSource());
        break;
      case WalletType.litecoin:
        node = getLitecoinDefaultElectrumServer(nodes: getNodeSource())!;
        break;
      case WalletType.haven:
        node = getHavenDefaultNode(nodes: getNodeSource())!;
        break;
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }

    await setAsCurrent(node);
  }

  @action
  Future<void> delete(Node node) async => node.delete();

  Future<void> setAsCurrent(Node? node) async {
    if(node==null)return;
    if(network==NetworkKind.mainnet)
      settingsStore.nodesMainnet[wallet.type] = node;
    else
      settingsStore.nodesTestnet[wallet.type] = node;
  }
}
