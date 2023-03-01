import 'dart:async';

import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:connectivity/connectivity.dart';

import '../di.dart';
import '../view_model/dashboard/dashboard_view_model.dart';
import '../view_model/node_list/node_list_view_model.dart';

Timer? _checkConnectionTimer;

void startCheckConnectionReaction(
    WalletBase wallet, SettingsStore settingsStore,
    {int timeInterval = 5}) {
  _checkConnectionTimer?.cancel();
  _checkConnectionTimer =
      Timer.periodic(Duration(seconds: timeInterval), (_) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());

      if (connectivityResult == ConnectivityResult.none) {
        wallet.syncStatus = FailedSyncStatus();
        return;
      }

      if (wallet.syncStatus is LostConnectionSyncStatus ||
          wallet.syncStatus is FailedSyncStatus) {
        NetworkKind networkKind = await getIt.get<DashboardViewModel>().currentNetwork();
        final alive =
            await settingsStore.getCurrentNode(wallet.type, networkKind).requestNode();

        if (alive) {
          await wallet.connectToNode(
              node: settingsStore.getCurrentNode(wallet.type, networkKind));
        }
      }
    } catch (e) {
      print(e.toString());
    }
  });
}
