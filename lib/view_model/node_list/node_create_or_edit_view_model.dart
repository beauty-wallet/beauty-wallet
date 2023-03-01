import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';

part 'node_create_or_edit_view_model.g.dart';

class NodeCreateOrEditViewModel = NodeCreateOrEditViewModelBase
    with _$NodeCreateOrEditViewModel;

abstract class NodeCreateOrEditViewModelBase with Store {
  NodeCreateOrEditViewModelBase(this._nodeSourceMainnet, this._nodeSourceTestnet, this._walletType, this._settingsStore)
      : state = InitialExecutionState(),
        connectionState = InitialExecutionState(),
        useSSL = false,
        address = '',
        port = '',
        login = '',
        password = '',
        trusted = false;

  @observable
  ExecutionState state;

  @observable
  String address;

  @observable
  String port;

  @observable
  String login;

  @observable
  String password;

  @observable
  ExecutionState connectionState;

  @observable
  bool useSSL;

  @observable
  bool trusted;

  @computed
  bool get isReady =>
      address.isNotEmpty && port.isNotEmpty;

  bool get hasAuthCredentials => _walletType == WalletType.monero ||
    _walletType == WalletType.haven;

  String get uri {
    var uri = address;

    if (port.isNotEmpty) {
      uri += ':' + port;
    }

    return uri;
  }

  final WalletType _walletType;
  final Box<Node> _nodeSourceMainnet;
  final Box<Node> _nodeSourceTestnet;
  final SettingsStore _settingsStore;

  @action
  void reset() {
    address = '';
    port = '';
    login = '';
    password = '';
    useSSL = false;
    trusted = false;
  }

  @action
  Future<void> save({required NetworkKind networkKind, bool saveAsCurrent = false, }) async {
    try {
      state = IsExecutingState();
      final node =
          Node(uri: uri, type: _walletType, login: login, password: password,
              useSSL: useSSL, trusted: trusted);
      await (networkKind==NetworkKind.mainnet?_nodeSourceMainnet:_nodeSourceTestnet).add(node);

      if (saveAsCurrent) {
        (networkKind==NetworkKind.mainnet?_settingsStore.nodesMainnet:_settingsStore.nodesTestnet)[_walletType] = node;
      }

      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> connect() async {
    try {
      connectionState = IsExecutingState();
      final node =
        Node(uri: uri, type: _walletType, login: login, password: password);
      final isAlive = await node.requestNode();
      connectionState = ExecutedSuccessfullyState(payload: isAlive);
    } catch (e) {
      connectionState = FailureState(e.toString());
    }
  }
}
