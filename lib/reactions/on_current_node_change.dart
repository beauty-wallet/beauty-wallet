import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/store/app_store.dart';

ReactionDisposer? _onCurrentNodeChangeReaction;

void startOnCurrentNodeChangeReaction(AppStore appStore, NetworkKind networkKind) {
  _onCurrentNodeChangeReaction?.reaction.dispose();
  ObservableMap<WalletType, Node> nodes = networkKind==NetworkKind.mainnet?
    appStore.settingsStore.nodesMainnet:appStore.settingsStore.nodesTestnet;
  nodes.observe((change) async {
    try {
      await appStore.wallet!.connectToNode(node: change.newValue!);
    } catch (e) {
      print(e.toString());
    }
  });
}
