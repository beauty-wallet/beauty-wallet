import 'dart:io' show File, Platform;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/fs_migration.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:collection/collection.dart';

const newCakeWalletMoneroUri = 'xmr-node.tranoo.com:18081';
const cakeWalletBitcoinElectrumUri = 'electrum.tranoo.com:50002';
const cakeWalletLitecoinElectrumUri = 'ltc-electrum.tranoo.com:50002';
const havenDefaultNodeUri = 'nodes.havenprotocol.org:443';

Future defaultSettingsMigration(
    {required int version,
    required SharedPreferences sharedPreferences,
    required FlutterSecureStorage secureStorage,
    required Box<Node> nodesMainnet,
    required Box<Node> nodesTestnet,
    required Box<WalletInfo> walletInfoSource,
    required Box<Trade> tradeSource,
    required Box<Contact> contactSource}) async {
  print('Migration: defaultSettingsMigration entered');
  if (Platform.isIOS) {
    await ios_migrate_v1(walletInfoSource, tradeSource, contactSource);
  }

  final currentVersion = sharedPreferences
          .getInt(PreferencesKey.currentDefaultSettingsMigrationVersion) ??
      0;
  if (currentVersion >= version) {
    print('Migration: currentVersion >= version');
    return;
  }

  final migrationVersionsLength = version - currentVersion;
  final migrationVersions = List<int>.generate(
      migrationVersionsLength, (i) => currentVersion + (i + 1));

  await Future.forEach(migrationVersions, (int version) async {
    try {
      print('Migration: version ${version} entered');
      switch (version) {
        case 1:
          print('Migration: version ${version}: p1');
          await sharedPreferences.setString(
              PreferencesKey.currentFiatCurrencyKey,
              FiatCurrency.usd.toString());
          print('Migration: version ${version}: p2');
          await sharedPreferences.setInt(
              PreferencesKey.currentTransactionPriorityKeyLegacy,
              monero!.getDefaultTransactionPriority().raw);
          print('Migration: version ${version}: p3');
          await sharedPreferences.setInt(
              PreferencesKey.currentBalanceDisplayModeKey,
              BalanceDisplayMode.availableBalance.raw);
          print('Migration: version ${version}: p4');
          await sharedPreferences.setBool('save_recipient_address', true);
          print('Migration: version ${version}: p5');
          await resetToDefault(nodesMainnet, nodesTestnet);
          print('Migration: version ${version}: p6');
          await changeMoneroCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodesMainnet: nodesMainnet);
          print('Migration: version ${version}: p7');
          await changeBitcoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodesMainnet: nodesMainnet);
          print('Migration: version ${version}: p8');
          await changeLitecoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodesMainnet: nodesMainnet);
          print('Migration: version ${version}: p9');
          await changeHavenCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodesMainnet: nodesMainnet);
          print('Migration: version ${version}: p10');
          break;
        case 2:
          await replaceNodesMigration(nodes: nodesMainnet);
          await replaceDefaultNode(
              sharedPreferences: sharedPreferences, nodes: nodesMainnet);

          break;
        case 3:
          await updateNodeTypes(nodes: nodesMainnet);
          await addBitcoinElectrumServerList(nodes: nodesMainnet, networkKind: NetworkKind.mainnet);

          break;
        case 4:
          await changeBitcoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodesMainnet: nodesMainnet);
          break;

        case 5:
          await addAddressesForMoneroWallets(walletInfoSource);
          break;

        case 6:
          await updateDisplayModes(sharedPreferences);
          break;

        case 9:
          await generateBackupPassword(secureStorage);
          break;

        case 10:
          await changeTransactionPriorityAndFeeRateKeys(sharedPreferences);
          break;

        case 11:
          await changeDefaultMoneroNode(nodesMainnet, sharedPreferences);
          break;

        case 12:
          await checkCurrentNodes(nodesMainnet, sharedPreferences);
          break;

        case 13:
          await resetBitcoinElectrumServer(nodesMainnet, sharedPreferences);
          break;

        case 15:
          await addLitecoinElectrumServerList(nodes: nodesMainnet, networkKind: NetworkKind.mainnet);
          await changeLitecoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodesMainnet: nodesMainnet);
          await checkCurrentNodes(nodesMainnet, sharedPreferences);
          break;

        case 16:
          await addHavenNodeList(nodes: nodesMainnet, networkKind: NetworkKind.mainnet);
          await changeHavenCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodesMainnet: nodesMainnet);
          await checkCurrentNodes(nodesMainnet, sharedPreferences);
          break;

        case 17:
          await changeDefaultHavenNode(nodesMainnet);
          break;

        case 18:
          await addOnionNode(nodesMainnet);
          break;

        case 19:
          await validateBitcoinSavedTransactionPriority(sharedPreferences);
          break;

        default:
          break;
      }

      print('Migration: version ${version} sh pref');
      await sharedPreferences.setInt(
          PreferencesKey.currentDefaultSettingsMigrationVersion, version);
      print('Migration: version ${version} exited w/o ex');
    } catch (e) {
      print('Migration error: ${e.runtimeType.toString()}: ${e.toString()}');
      print('Migration: version ${version} exited w/ ex');
    }
    print('Migration: exiting');
  });

  await sharedPreferences.setInt(
      PreferencesKey.currentDefaultSettingsMigrationVersion, version);
}

Future<void> validateBitcoinSavedTransactionPriority(SharedPreferences sharedPreferences) async {
  if (bitcoin == null) {
    return;
  }
  final int? savedBitcoinPriority =
      sharedPreferences.getInt(PreferencesKey.bitcoinTransactionPriority);
  if (!bitcoin!.getTransactionPriorities().any((element) => element.raw == savedBitcoinPriority)) {
    await sharedPreferences.setInt(
        PreferencesKey.bitcoinTransactionPriority, bitcoin!.getMediumTransactionPriority().serialize());
  }
}

Future<void> addOnionNode(Box<Node> nodes) async {
  final onionNodeUri = "cakexmrl7bonq7ovjka5kuwuyd3f7qnkz6z6s6dmsy3uckwra7bvggyd.onion:18081";

  // check if the user has this node before (added it manually)
  if (nodes.values.firstWhereOrNull((element) => element.uriRaw == onionNodeUri) == null) {
    await nodes.add(Node(uri: onionNodeUri, type: WalletType.monero));
  }
}

Future<void> replaceNodesMigration({required Box<Node> nodes}) async {
  final replaceNodes = <String, Node>{
    'eu-node.cakewallet.io:18081':
        Node(uri: 'xmr-node-eu.tranoo.com:18081', type: WalletType.monero),
    'node.cakewallet.io:18081': Node(
        uri: 'xmr-node-usa-east.tranoo.com:18081', type: WalletType.monero),
    'node.xmr.ru:13666':
        Node(uri: 'node.monero.net:18081', type: WalletType.monero)
  };

  nodes.values.forEach((Node node) async {
    final nodeToReplace = replaceNodes[node.uri];

    if (nodeToReplace != null) {
      node.uriRaw = nodeToReplace.uriRaw;
      node.login = nodeToReplace.login;
      node.password = nodeToReplace.password;
      await node.save();
    }
  });
}

Future<void> changeMoneroCurrentNodeToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodesMainnet}) async {
  print("changeMoneroCurrentNodeToDefault enter");
  final node = getMoneroDefaultNode(nodes: nodesMainnet);
  print("changeMoneroCurrentNodeToDefault p2");
  final nodeId = node?.key as int? ?? 0; // 0 - England
  print("changeMoneroCurrentNodeToDefault p3");
  if(nodeId!=null)await sharedPreferences.setInt(PreferencesKey.currentNodeIdKey, nodeId);
  print("changeMoneroCurrentNodeToDefault leave");
}

Node? getBitcoinDefaultElectrumServer({required Box<Node> nodes}) {
  Box<Node> nodes0 = nodes;
  return nodes0.values.firstWhereOrNull(
          (Node node) => node.uriRaw == cakeWalletBitcoinElectrumUri)
          ?? nodes.values.firstWhereOrNull((node) => node.type == WalletType.bitcoin);
}

Node? getLitecoinDefaultElectrumServer({required Box<Node> nodes}) {
    return nodes.values.firstWhereOrNull(
          (Node node) => node.uriRaw == cakeWalletLitecoinElectrumUri)
          ?? nodes.values.firstWhereOrNull((node) => node.type == WalletType.litecoin);
}

Node? getHavenDefaultNode({required Box<Node> nodes}) {
    return nodes.values.firstWhereOrNull(
          (Node node) => node.uriRaw == havenDefaultNodeUri)
          ?? nodes.values.firstWhereOrNull((node) => node.type == WalletType.haven);
}

Node? getMoneroDefaultNode({required Box<Node> nodes}) {
  print("getMoneroDefaultNode enter");
  final timeZone = DateTime.now().timeZoneOffset.inHours;
  var nodeUri = '';

  print("getMoneroDefaultNode p2");
  if (timeZone >= 1) {
    // Eurasia
    nodeUri = 'xmr-node-eu.tranoo.com:18081';
  } else if (timeZone <= -4) {
    // America
    nodeUri = 'xmr-node-usa-east.tranoo.com:18081';
  }
  print("getMoneroDefaultNode p3");

  if(nodes.values.isEmpty) {
    print('getMoneroDefaultNode: empty.p5');
    return null;
  }
  try {
    print("getMoneroDefaultNode p4");
    return nodes.values
        .firstWhereOrNull((Node node) => node.uriRaw == nodeUri);
  } catch(e) {
    print('getMoneroDefaultNode ex: ${e.runtimeType.toString()}: ${e.toString()}');
    return nodes.values.first;
  }
}

Future<void> changeBitcoinCurrentElectrumServerToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodesMainnet}) async {
  final server = getBitcoinDefaultElectrumServer(nodes: nodesMainnet);
  final serverId = server?.key as int? ?? 0;

  await sharedPreferences.setInt(PreferencesKey.currentBitcoinElectrumSererIdKey, serverId);
}

Future<void> changeLitecoinCurrentElectrumServerToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodesMainnet}) async {
  final server = getLitecoinDefaultElectrumServer(nodes: nodesMainnet);
  final serverId = server?.key as int? ?? 0;

  await sharedPreferences.setInt(PreferencesKey.currentLitecoinElectrumSererIdKey, serverId);
}

Future<void> changeHavenCurrentNodeToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodesMainnet}) async {
  final node = getHavenDefaultNode(nodes: nodesMainnet);
  final nodeId = node?.key as int? ?? 0;

  await sharedPreferences.setInt(PreferencesKey.currentHavenNodeIdKey, nodeId);
}

Future<void> replaceDefaultNode(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes}) async {
  const nodesForReplace = <String>[
    'xmr-node-uk.tranoo.com:18081',
    'eu-node.cakewallet.io:18081',
    'node.cakewallet.io:18081'
  ];
  final currentNodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentNode =
      nodes.values.firstWhereOrNull((Node node) => node.key == currentNodeId);
  final needToReplace =
      currentNode == null ? true : nodesForReplace.contains(currentNode.uriRaw);

  if (!needToReplace) {
    return;
  }

  await changeMoneroCurrentNodeToDefault(
      sharedPreferences: sharedPreferences, nodesMainnet: nodes);
}

Future<void> updateNodeTypes({required Box<Node> nodes}) async {
  nodes.values.forEach((node) async {
    if (node.type == null) {
      node.type = WalletType.monero;
      await node.save();
    }
  });
}

Future<void> addBitcoinElectrumServerList({required Box<Node> nodes, required NetworkKind networkKind}) async {
  final serverList = await loadBitcoinElectrumServerList(networkKind);
  for (var node in serverList) {
    if (nodes.values.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await nodes.add(node);
    }
  }
}

Future<void> addLitecoinElectrumServerList({required Box<Node> nodes, required NetworkKind networkKind}) async {
  final serverList = await loadLitecoinElectrumServerList(networkKind);
  for (var node in serverList) {
    if (nodes.values.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await nodes.add(node);
    }
  }
}

Future<void> addHavenNodeList({required Box<Node> nodes, required NetworkKind networkKind}) async {
  final nodeList = await loadDefaultHavenNodes(networkKind);
  for (var node in nodeList) {
    if (nodes.values.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await nodes.add(node);
    }
  }
}

Future<void> addAddressesForMoneroWallets(
    Box<WalletInfo> walletInfoSource) async {
  print("addAddressesForMoneroWallets entered");
  final moneroWalletsInfo =
      walletInfoSource.values.where((info) => info.type == WalletType.monero);
  moneroWalletsInfo.forEach((info) async {
    try {
      print("addAddressesForMoneroWallets: info '${info.toString()}'");
      final walletPath =
          await pathForWallet(name: info.name, type: WalletType.monero);
      final addressFilePath = '$walletPath.address.txt';
      final addressFile = File(addressFilePath);

      print("addAddressesForMoneroWallets: p3");
      if (!addressFile.existsSync()) {
        print("addAddressesForMoneroWallets: p4");
        return;
      }
      print("addAddressesForMoneroWallets: p5");
      final addressText = await addressFile.readAsString();
      info.address = addressText;
      print("addAddressesForMoneroWallets: p6");
      await info.save();
      print("addAddressesForMoneroWallets: p7");
    } catch (e) {
      print("addAddressesForMoneroWallets: ${e.runtimeType.toString()}: ${e.toString()}");
    }
    print("addAddressesForMoneroWallets: leaving");
  });
}

Future<void> updateDisplayModes(SharedPreferences sharedPreferences) async {
  final currentBalanceDisplayMode =
      sharedPreferences.getInt(PreferencesKey.currentBalanceDisplayModeKey) ?? -1;
  final balanceDisplayMode = currentBalanceDisplayMode < 2 ? 3 : 2;
  await sharedPreferences.setInt(
      PreferencesKey.currentBalanceDisplayModeKey, balanceDisplayMode);
}

Future<void> generateBackupPassword(FlutterSecureStorage secureStorage) async {
  final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);

  if ((await secureStorage.read(key: key))?.isNotEmpty ?? false) {
    return;
  }

  final password = encrypt.Key.fromSecureRandom(32).base16;
  await secureStorage.write(key: key, value: password);
}

Future<void> changeTransactionPriorityAndFeeRateKeys(
    SharedPreferences sharedPreferences) async {
  final legacyTransactionPriority = sharedPreferences
      .getInt(PreferencesKey.currentTransactionPriorityKeyLegacy)!;
  await sharedPreferences.setInt(
      PreferencesKey.moneroTransactionPriority, legacyTransactionPriority);
  await sharedPreferences.setInt(PreferencesKey.bitcoinTransactionPriority,
      bitcoin!.getMediumTransactionPriority().serialize());
}

Future<void> changeDefaultMoneroNode(
    Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
  const cakeWalletMoneroNodeUriPattern = '.tranoo.com';
  final currentMoneroNodeId =
      sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentMoneroNode =
      nodeSource.values.firstWhereOrNull((node) => node.key == currentMoneroNodeId);
  final needToReplaceCurrentMoneroNode =
      currentMoneroNode?.uri.toString().contains(cakeWalletMoneroNodeUriPattern);

  nodeSource.values.forEach((node) async {
    if (node.type == WalletType.monero &&
        node.uri.toString().contains(cakeWalletMoneroNodeUriPattern)) {
      await node.delete();
    }
  });

  final newCakeWalletNode =
      Node(uri: newCakeWalletMoneroUri, type: WalletType.monero);

  await nodeSource.add(newCakeWalletNode);

  if (needToReplaceCurrentMoneroNode!=null && needToReplaceCurrentMoneroNode) {
    await sharedPreferences.setInt(
        PreferencesKey.currentNodeIdKey, newCakeWalletNode.key as int);
  }
}

Future<void> checkCurrentNodes(
    Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
  final currentMoneroNodeId =
      sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentBitcoinElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
  final currentLitecoinElectrumSeverId = sharedPreferences
      .getInt(PreferencesKey.currentLitecoinElectrumSererIdKey);
  final currentHavenNodeId = sharedPreferences
      .getInt(PreferencesKey.currentHavenNodeIdKey);
  final currentMoneroNode = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentMoneroNodeId);
  final currentBitcoinElectrumServer = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentBitcoinElectrumSeverId);
  final currentLitecoinElectrumServer = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentLitecoinElectrumSeverId);
  final currentHavenNodeServer = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentHavenNodeId);

  if (currentMoneroNode == null) {
    final newCakeWalletNode =
        Node(uri: newCakeWalletMoneroUri, type: WalletType.monero);
    await nodeSource.add(newCakeWalletNode);
    await sharedPreferences.setInt(
        PreferencesKey.currentNodeIdKey, newCakeWalletNode.key as int);
  }

  if (currentBitcoinElectrumServer == null) {
    final cakeWalletElectrum =
        Node(uri: cakeWalletBitcoinElectrumUri, type: WalletType.bitcoin);
    await nodeSource.add(cakeWalletElectrum);
    await sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey,
        cakeWalletElectrum.key as int);
  }

  if (currentLitecoinElectrumServer == null) {
    final cakeWalletElectrum =
        Node(uri: cakeWalletLitecoinElectrumUri, type: WalletType.litecoin);
    await nodeSource.add(cakeWalletElectrum);
    await sharedPreferences.setInt(
        PreferencesKey.currentLitecoinElectrumSererIdKey,
        cakeWalletElectrum.key as int);
  }

  if (currentHavenNodeServer == null) {
    final node = Node(uri: havenDefaultNodeUri, type: WalletType.haven);
    await nodeSource.add(node);
    await sharedPreferences.setInt(
        PreferencesKey.currentHavenNodeIdKey, node.key as int);
  }
}

Future<void> resetBitcoinElectrumServer(
    Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
  final currentElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
  final oldElectrumServer = nodeSource.values.firstWhereOrNull(
      (node) => node.uri.toString().contains('electrumx.tranoo.com'));
  var cakeWalletNode = nodeSource.values.firstWhereOrNull(
      (node) => node.uriRaw.toString() == cakeWalletBitcoinElectrumUri);

  if (cakeWalletNode == null) {
    cakeWalletNode =
        Node(uri: cakeWalletBitcoinElectrumUri, type: WalletType.bitcoin);
    await nodeSource.add(cakeWalletNode);
  }

  if (currentElectrumSeverId == oldElectrumServer?.key) {
    await sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey,
        cakeWalletNode.key as int);
  }

  await oldElectrumServer?.delete();
}

Future<void> changeDefaultHavenNode(
    Box<Node> nodeSource) async {
  const previousHavenDefaultNodeUri = 'vault.havenprotocol.org:443';
  final havenNodes = nodeSource.values.where(
      (node) => node.uriRaw == previousHavenDefaultNodeUri);
  havenNodes.forEach((node) async {
    node.uriRaw = havenDefaultNodeUri;
    await node.save();
  });
}
