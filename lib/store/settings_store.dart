import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info/package_info.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/entities/action_list_display_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';

part 'settings_store.g.dart';

class SettingsStore = SettingsStoreBase with _$SettingsStore;

abstract class SettingsStoreBase with Store {
  SettingsStoreBase(
      {required SharedPreferences sharedPreferences,
      required FiatCurrency initialFiatCurrency,
      required BalanceDisplayMode initialBalanceDisplayMode,
      required bool initialSaveRecipientAddress,
      required FiatApiMode initialFiatMode,
      required bool initialAllowBiometricalAuthentication,
      required bool initialExchangeEnabled,
      required ThemeBase initialTheme,
      required int initialPinLength,
      required String initialLanguageCode,
      // required String initialCurrentLocale,
      required this.appVersion,
        required Map<WalletType, Node> nodesMainnet,
        required Map<WalletType, Node> nodesTestnet,
      required this.shouldShowYatPopup,
      required this.isBitcoinBuyEnabled,
      required this.actionlistDisplayMode,
      required this.pinTimeOutDuration,
      TransactionPriority? initialBitcoinTransactionPriority,
      TransactionPriority? initialMoneroTransactionPriority,
      TransactionPriority? initialHavenTransactionPriority,
      TransactionPriority? initialLitecoinTransactionPriority})
  :
        nodesMainnet = ObservableMap<WalletType, Node>.of(nodesMainnet),
        nodesTestnet = ObservableMap<WalletType, Node>.of(nodesTestnet),
    _sharedPreferences = sharedPreferences,
    fiatCurrency = initialFiatCurrency,
    balanceDisplayMode = initialBalanceDisplayMode,
    shouldSaveRecipientAddress = initialSaveRecipientAddress,
    fiatApiMode = initialFiatMode,
    allowBiometricalAuthentication = initialAllowBiometricalAuthentication,
    disableExchange = initialExchangeEnabled,
    currentTheme = initialTheme,
    pinCodeLength = initialPinLength,
    languageCode = initialLanguageCode,
    priority = ObservableMap<WalletType, TransactionPriority>() {
    //this.nodes = ObservableMap<WalletType, Node>.of(nodes);

    if (initialMoneroTransactionPriority != null) {
        priority[WalletType.monero] = initialMoneroTransactionPriority;
    }

    if (initialBitcoinTransactionPriority != null) {
        priority[WalletType.bitcoin] = initialBitcoinTransactionPriority;
    }

    if (initialHavenTransactionPriority != null) {
        priority[WalletType.haven] = initialHavenTransactionPriority;
    }

    if (initialLitecoinTransactionPriority != null) {
        priority[WalletType.litecoin] = initialLitecoinTransactionPriority;
    }

    reaction(
        (_) => fiatCurrency,
        (FiatCurrency fiatCurrency) => sharedPreferences.setString(
            PreferencesKey.currentFiatCurrencyKey, fiatCurrency.serialize()));

    reaction(
        (_) => shouldShowYatPopup,
        (bool shouldShowYatPopup) => sharedPreferences
             .setBool(PreferencesKey.shouldShowYatPopup, shouldShowYatPopup));

    priority.observe((change) {
      final String? key;
      switch (change.key) {
        case WalletType.monero:
          key = PreferencesKey.moneroTransactionPriority;
          break;
        case WalletType.bitcoin:
          key = PreferencesKey.bitcoinTransactionPriority;
          break;
        case WalletType.litecoin:
          key = PreferencesKey.litecoinTransactionPriority;
          break;
        case WalletType.haven:
          key = PreferencesKey.havenTransactionPriority;
          break;
        default:
          key = null;
      }

      if (change.newValue != null && key != null) {
        sharedPreferences.setInt(key, change.newValue!.serialize());
      }
    });

    reaction(
        (_) => shouldSaveRecipientAddress,
        (bool shouldSaveRecipientAddress) => sharedPreferences.setBool(
            PreferencesKey.shouldSaveRecipientAddressKey,
            shouldSaveRecipientAddress));

    reaction(
            (_) => fiatApiMode,
            (FiatApiMode mode) => sharedPreferences.setInt(
            PreferencesKey.currentFiatApiModeKey, mode.serialize()));

    reaction(
        (_) => currentTheme,
        (ThemeBase theme) =>
            sharedPreferences.setInt(PreferencesKey.currentTheme, theme.raw));

    reaction(
        (_) => allowBiometricalAuthentication,
        (bool biometricalAuthentication) => sharedPreferences.setBool(
            PreferencesKey.allowBiometricalAuthenticationKey,
            biometricalAuthentication));

    reaction(
        (_) => pinCodeLength,
        (int pinLength) => sharedPreferences.setInt(
            PreferencesKey.currentPinLength, pinLength));

    reaction(
        (_) => languageCode,
        (String languageCode) => sharedPreferences.setString(
            PreferencesKey.currentLanguageCode, languageCode));

    reaction(
        (_) => pinTimeOutDuration,
        (PinCodeRequiredDuration pinCodeInterval) => sharedPreferences.setInt(
            PreferencesKey.pinTimeOutDuration, pinCodeInterval.value));

    reaction(
        (_) => balanceDisplayMode,
        (BalanceDisplayMode mode) => sharedPreferences.setInt(
            PreferencesKey.currentBalanceDisplayModeKey, mode.serialize()));

    reaction(
            (_) => disableExchange,
            (bool disableExchange) => sharedPreferences.setBool(
            PreferencesKey.disableExchangeKey, disableExchange));

    this
        .nodesMainnet
        .observe((change) {
      if (change.newValue != null && change.key != null) {
        _saveCurrentNode(change.newValue!, change.key!, NetworkKind.mainnet);
      }
    });
    this
        .nodesTestnet
        .observe((change) {
      if (change.newValue != null && change.key != null) {
        _saveCurrentNode(change.newValue!, change.key!, NetworkKind.testnet);
      }
    });
  }

  static const defaultPinLength = 4;
  static const defaultActionsMode = 11;
  static const defaultPinCodeTimeOutDuration = PinCodeRequiredDuration.tenminutes;

  @observable
  FiatCurrency fiatCurrency;

  @observable
  bool shouldShowYatPopup;

  @observable
  ObservableList<ActionListDisplayMode> actionlistDisplayMode;

  @observable
  BalanceDisplayMode balanceDisplayMode;

  @observable
  FiatApiMode fiatApiMode;

  @observable
  bool shouldSaveRecipientAddress;

  @observable
  bool allowBiometricalAuthentication;

  @observable
  bool disableExchange;

  @observable
  ThemeBase currentTheme;

  @observable
  int pinCodeLength;

  @observable
  PinCodeRequiredDuration pinTimeOutDuration;

  @computed
  ThemeData get theme => currentTheme.themeData;

  @observable
  String languageCode;

  @observable
  ObservableMap<WalletType, TransactionPriority> priority;

  String appVersion;

  SharedPreferences _sharedPreferences;

  ObservableMap<WalletType, Node> nodesMainnet;
  ObservableMap<WalletType, Node> nodesTestnet;

  Node getCurrentNode(WalletType walletType, NetworkKind network) {
    final node = network==NetworkKind.mainnet?nodesMainnet[walletType]:nodesTestnet[walletType];

    if (node == null) {
        throw Exception('No node found for wallet type: ${walletType.toString()}');
    }

    return node;
  }

  bool isBitcoinBuyEnabled;

  bool get shouldShowReceiveWarning =>
    _sharedPreferences.getBool(PreferencesKey.shouldShowReceiveWarning) ?? true;

  Future<void> setShouldShowReceiveWarning(bool value) async =>
    _sharedPreferences.setBool(PreferencesKey.shouldShowReceiveWarning, value);

  static Future<SettingsStore> load(
      {
        required Box<Node> nodeSourceMainnet,
        required Box<Node> nodeSourceTestnet,
        required bool isBitcoinBuyEnabled,
        FiatCurrency initialFiatCurrency = FiatCurrency.usd,
        BalanceDisplayMode initialBalanceDisplayMode =
            BalanceDisplayMode.availableBalance}) async {

    final sharedPreferences = await getIt.getAsync<SharedPreferences>();
    final currentFiatCurrency = FiatCurrency.deserialize(raw:
            sharedPreferences.getString(PreferencesKey.currentFiatCurrencyKey)!);

    TransactionPriority? moneroTransactionPriority =
        monero?.deserializeMoneroTransactionPriority(
            raw: sharedPreferences
                .getInt(PreferencesKey.moneroTransactionPriority)!);
    TransactionPriority? bitcoinTransactionPriority =
        bitcoin?.deserializeBitcoinTransactionPriority(sharedPreferences
                .getInt(PreferencesKey.bitcoinTransactionPriority)!);

    TransactionPriority? havenTransactionPriority;
    TransactionPriority? litecoinTransactionPriority;

    if (sharedPreferences.getInt(PreferencesKey.havenTransactionPriority) != null) {
      havenTransactionPriority = monero?.deserializeMoneroTransactionPriority(
          raw: sharedPreferences.getInt(PreferencesKey.havenTransactionPriority)!);
    }
    if (sharedPreferences.getInt(PreferencesKey.litecoinTransactionPriority) != null) {
      litecoinTransactionPriority = bitcoin?.deserializeLitecoinTransactionPriority(
          sharedPreferences.getInt(PreferencesKey.litecoinTransactionPriority)!);
    }

    moneroTransactionPriority ??= monero?.getDefaultTransactionPriority();
    bitcoinTransactionPriority ??= bitcoin?.getMediumTransactionPriority();
    havenTransactionPriority ??= monero?.getDefaultTransactionPriority();
    litecoinTransactionPriority ??= bitcoin?.getLitecoinTransactionPriorityMedium();

    final currentBalanceDisplayMode = BalanceDisplayMode.deserialize(
        raw: sharedPreferences
            .getInt(PreferencesKey.currentBalanceDisplayModeKey)!);
    // FIX-ME: Check for which default value we should have here
    final shouldSaveRecipientAddress =
        sharedPreferences.getBool(PreferencesKey.shouldSaveRecipientAddressKey) ?? false;
    final currentFiatApiMode = FiatApiMode.deserialize(
        raw: sharedPreferences
            .getInt(PreferencesKey.currentFiatApiModeKey) ?? FiatApiMode.enabled.raw);
    final allowBiometricalAuthentication = sharedPreferences
            .getBool(PreferencesKey.allowBiometricalAuthenticationKey) ??
        false;
    final disableExchange = sharedPreferences
            .getBool(PreferencesKey.disableExchangeKey) ?? false;
    final legacyTheme =
        (sharedPreferences.getBool(PreferencesKey.isDarkThemeLegacy) ?? false)
            ? ThemeType.dark.index
            : ThemeType.bright.index;
    final savedTheme = ThemeList.deserialize(
        raw: sharedPreferences.getInt(PreferencesKey.currentTheme) ??
            legacyTheme);
    final actionListDisplayMode = ObservableList<ActionListDisplayMode>();
    actionListDisplayMode.addAll(deserializeActionlistDisplayModes(
        sharedPreferences.getInt(PreferencesKey.displayActionListModeKey) ??
            defaultActionsMode));
    var pinLength = sharedPreferences.getInt(PreferencesKey.currentPinLength);
    final timeOutDuration =  sharedPreferences.getInt(PreferencesKey.pinTimeOutDuration);
    final pinCodeTimeOutDuration = timeOutDuration != null
        ? PinCodeRequiredDuration.deserialize(raw: timeOutDuration)
        : defaultPinCodeTimeOutDuration;
    
    // If no value
    if (pinLength == null || pinLength == 0) {
      pinLength = defaultPinLength;
    }

    final savedLanguageCode =
        sharedPreferences.getString(PreferencesKey.currentLanguageCode) ??
            await LanguageService.localeDetection();
    final nodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
    final bitcoinElectrumServerId = sharedPreferences
        .getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
    final litecoinElectrumServerId = sharedPreferences
        .getInt(PreferencesKey.currentLitecoinElectrumSererIdKey);
    final havenNodeId = sharedPreferences
        .getInt(PreferencesKey.currentHavenNodeIdKey);
    final nodeIdTestnet = sharedPreferences.getInt(PreferencesKey.currentNodeIdTestnetKey);
    final bitcoinElectrumServerIdTestnet = sharedPreferences
        .getInt(PreferencesKey.currentBitcoinElectrumSererIdTestnetKey);
    final litecoinElectrumServerTestnetId = sharedPreferences
        .getInt(PreferencesKey.currentLitecoinElectrumSererIdTestnetKey);
    final havenNodeIdTestnet = sharedPreferences
        .getInt(PreferencesKey.currentHavenNodeIdTestnetKey);
    final moneroNode = nodeSourceMainnet.get(nodeId);
    final moneroNodeTestnet = nodeSourceTestnet.get(nodeIdTestnet);
    final bitcoinElectrumServer = nodeSourceMainnet.get(bitcoinElectrumServerId);
    final bitcoinElectrumServerTestnet = nodeSourceTestnet.get(bitcoinElectrumServerIdTestnet);
    final litecoinElectrumServer = nodeSourceMainnet.get(litecoinElectrumServerId);
    final havenNode = nodeSourceMainnet.get(havenNodeId);
    final litecoinElectrumServerTestnet = nodeSourceTestnet.get(litecoinElectrumServerTestnetId);
    final havenNodeTestnet = nodeSourceTestnet.get(havenNodeIdTestnet);
    final packageInfo = await PackageInfo.fromPlatform();
    final shouldShowYatPopup =
        sharedPreferences.getBool(PreferencesKey.shouldShowYatPopup) ?? true;

    final nodesMainnet = <WalletType, Node>{};
    final nodesTestnet = <WalletType, Node>{};

    if (moneroNode != null) {
      nodesMainnet[WalletType.monero] = moneroNode;
    }
    if (moneroNodeTestnet != null) {
      nodesTestnet[WalletType.monero] = moneroNodeTestnet;
    }

    if (bitcoinElectrumServer != null) {
      nodesMainnet[WalletType.bitcoin] = bitcoinElectrumServer;
    }
    if (bitcoinElectrumServerTestnet != null) {
      nodesTestnet[WalletType.bitcoin] = bitcoinElectrumServerTestnet;
    }

    if (litecoinElectrumServer != null) {
      nodesMainnet[WalletType.litecoin] = litecoinElectrumServer;
    }
    if (litecoinElectrumServerTestnet != null) {
      nodesTestnet[WalletType.litecoin] = litecoinElectrumServerTestnet;
    }

    if (havenNode != null) {
      nodesMainnet[WalletType.haven] = havenNode;
    }
    if (havenNodeTestnet != null) {
      nodesTestnet[WalletType.haven] = havenNodeTestnet;
    }

    return SettingsStore(
        sharedPreferences: sharedPreferences,
        nodesMainnet: nodesMainnet,
        nodesTestnet: nodesTestnet,
        appVersion: packageInfo.version,
        isBitcoinBuyEnabled: isBitcoinBuyEnabled,
        initialFiatCurrency: currentFiatCurrency,
        initialBalanceDisplayMode: currentBalanceDisplayMode,
        initialSaveRecipientAddress: shouldSaveRecipientAddress,
        initialFiatMode: currentFiatApiMode,
        initialAllowBiometricalAuthentication: allowBiometricalAuthentication,
        initialExchangeEnabled: disableExchange,
        initialTheme: savedTheme,
        actionlistDisplayMode: actionListDisplayMode,
        initialPinLength: pinLength,
        pinTimeOutDuration: pinCodeTimeOutDuration,
        initialLanguageCode: savedLanguageCode,
        initialMoneroTransactionPriority: moneroTransactionPriority,
        initialBitcoinTransactionPriority: bitcoinTransactionPriority,
        initialHavenTransactionPriority: havenTransactionPriority,
        initialLitecoinTransactionPriority: litecoinTransactionPriority,
        shouldShowYatPopup: shouldShowYatPopup);
  }

  Future<void> reload({required Box<Node> nodeSourceMainnet, required Box<Node> nodeSourceTestnet}) async {

    final sharedPreferences = await getIt.getAsync<SharedPreferences>();

    fiatCurrency = FiatCurrency.deserialize(
        raw: sharedPreferences.getString(PreferencesKey.currentFiatCurrencyKey)!);

    priority[WalletType.monero] = monero?.deserializeMoneroTransactionPriority(
        raw: sharedPreferences.getInt(PreferencesKey.moneroTransactionPriority)!) ??
        priority[WalletType.monero]!;
    priority[WalletType.bitcoin] = bitcoin?.deserializeBitcoinTransactionPriority(
        sharedPreferences.getInt(PreferencesKey.moneroTransactionPriority)!) ??
        priority[WalletType.bitcoin]!;

    if (sharedPreferences.getInt(PreferencesKey.havenTransactionPriority) != null) {
      priority[WalletType.haven] = monero?.deserializeMoneroTransactionPriority(
          raw: sharedPreferences.getInt(PreferencesKey.havenTransactionPriority)!) ??
          priority[WalletType.haven]!;
    }
    if (sharedPreferences.getInt(PreferencesKey.litecoinTransactionPriority) != null) {
      priority[WalletType.litecoin] = bitcoin?.deserializeLitecoinTransactionPriority(
          sharedPreferences.getInt(PreferencesKey.litecoinTransactionPriority)!) ??
          priority[WalletType.litecoin]!;
    }

    balanceDisplayMode = BalanceDisplayMode.deserialize(
        raw: sharedPreferences
            .getInt(PreferencesKey.currentBalanceDisplayModeKey)!);
    shouldSaveRecipientAddress =
        sharedPreferences.getBool(PreferencesKey.shouldSaveRecipientAddressKey) ?? shouldSaveRecipientAddress;
    allowBiometricalAuthentication = sharedPreferences
        .getBool(PreferencesKey.allowBiometricalAuthenticationKey) ??
        allowBiometricalAuthentication;
    disableExchange = sharedPreferences.getBool(PreferencesKey.disableExchangeKey) ?? disableExchange;
    final legacyTheme =
        (sharedPreferences.getBool(PreferencesKey.isDarkThemeLegacy) ?? false)
            ? ThemeType.dark.index
            : ThemeType.bright.index;
    currentTheme = ThemeList.deserialize(
        raw: sharedPreferences.getInt(PreferencesKey.currentTheme) ??
            legacyTheme);
    actionlistDisplayMode = ObservableList<ActionListDisplayMode>();
    actionlistDisplayMode.addAll(deserializeActionlistDisplayModes(
        sharedPreferences.getInt(PreferencesKey.displayActionListModeKey) ??
            defaultActionsMode));
    var pinLength = sharedPreferences.getInt(PreferencesKey.currentPinLength);
    // If no value
    if (pinLength == null || pinLength == 0) {
      pinLength = pinCodeLength;
    }
    pinCodeLength = pinLength;

    languageCode = sharedPreferences.getString(PreferencesKey.currentLanguageCode) ?? languageCode;
    shouldShowYatPopup = sharedPreferences.getBool(PreferencesKey.shouldShowYatPopup) ?? shouldShowYatPopup;

    final nodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
    final bitcoinElectrumServerId = sharedPreferences
        .getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
    final litecoinElectrumServerId = sharedPreferences
        .getInt(PreferencesKey.currentLitecoinElectrumSererIdKey);
    final havenNodeId = sharedPreferences
        .getInt(PreferencesKey.currentHavenNodeIdKey);
    final nodeIdT = sharedPreferences.getInt(PreferencesKey.currentNodeIdTestnetKey);
    final bitcoinElectrumServerIdT = sharedPreferences
        .getInt(PreferencesKey.currentBitcoinElectrumSererIdTestnetKey);
    final litecoinElectrumServerIdT = sharedPreferences
        .getInt(PreferencesKey.currentLitecoinElectrumSererIdTestnetKey);
    final havenNodeIdT = sharedPreferences
        .getInt(PreferencesKey.currentHavenNodeIdTestnetKey);
    final moneroNode = nodeSourceMainnet.get(nodeId);
    final bitcoinElectrumServer = nodeSourceMainnet.get(bitcoinElectrumServerId);
    final litecoinElectrumServer = nodeSourceMainnet.get(litecoinElectrumServerId);
    final havenNode = nodeSourceMainnet.get(havenNodeId);
    final moneroNodeT = nodeSourceTestnet.get(nodeIdT);
    final bitcoinElectrumServerT = nodeSourceTestnet.get(bitcoinElectrumServerIdT);
    final litecoinElectrumServerT = nodeSourceTestnet.get(litecoinElectrumServerIdT);
    final havenNodeT = nodeSourceTestnet.get(havenNodeIdT);

    if (moneroNode != null) {
      nodesMainnet[WalletType.monero] = moneroNode;
    }
    if (bitcoinElectrumServer != null) {
      nodesMainnet[WalletType.bitcoin] = bitcoinElectrumServer;
    }
    if (litecoinElectrumServer != null) {
      nodesMainnet[WalletType.litecoin] = litecoinElectrumServer;
    }
    if (havenNode != null) {
      nodesMainnet[WalletType.haven] = havenNode;
    }
    if (moneroNodeT != null) {
      nodesTestnet[WalletType.monero] = moneroNodeT;
    }
    if (bitcoinElectrumServerT != null) {
      nodesTestnet[WalletType.bitcoin] = bitcoinElectrumServerT;
    }
    if (litecoinElectrumServerT != null) {
      nodesTestnet[WalletType.litecoin] = litecoinElectrumServerT;
    }
    if (havenNodeT != null) {
      nodesTestnet[WalletType.haven] = havenNodeT;
    }
  }

  Future<void> _saveCurrentNode(Node node, WalletType walletType, NetworkKind network) async {
    switch (walletType) {
      case WalletType.bitcoin:
        if(network==NetworkKind.mainnet)
          await _sharedPreferences.setInt(PreferencesKey.currentBitcoinElectrumSererIdKey, node.key as int);
        else
          await _sharedPreferences.setInt(PreferencesKey.currentBitcoinElectrumSererIdTestnetKey, node.key as int);
        break;
      case WalletType.litecoin:
        if(network==NetworkKind.mainnet)
          await _sharedPreferences.setInt(
            PreferencesKey.currentLitecoinElectrumSererIdKey, node.key as int);
        else
          await _sharedPreferences.setInt(
              PreferencesKey.currentLitecoinElectrumSererIdTestnetKey, node.key as int);
        break;
      case WalletType.monero:
        if(network==NetworkKind.mainnet)
          await _sharedPreferences.setInt(
            PreferencesKey.currentNodeIdKey, node.key as int);
        else
          await _sharedPreferences.setInt(
              PreferencesKey.currentNodeIdTestnetKey, node.key as int);
        break;
      case WalletType.haven:
        if(network==NetworkKind.mainnet)
          await _sharedPreferences.setInt(
            PreferencesKey.currentHavenNodeIdKey, node.key as int);
        else
          await _sharedPreferences.setInt(
              PreferencesKey.currentHavenNodeIdTestnetKey, node.key as int);
        break;
      default:
        break;
    }

    if(network==NetworkKind.mainnet)
      nodesMainnet[walletType] = node;
    else
      nodesTestnet[walletType] = node;
  }
}
