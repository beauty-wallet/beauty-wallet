class PreferencesKey {
  static const currentWalletType = 'current_wallet_type';
  static const currentWalletName = 'current_wallet_name';
  static const currentNodeIdKey = 'current_node_id';
  static const currentBitcoinElectrumSererIdKey = 'current_node_id_btc';
  static const currentLitecoinElectrumSererIdKey = 'current_node_id_ltc';
  static const currentHavenNodeIdKey = 'current_node_id_xhv';
  static const currentNodeIdTestnetKey = 'current_node_id_testnet';
  static const currentBitcoinElectrumSererIdTestnetKey = 'current_node_id_btc_testnet';
  static const currentLitecoinElectrumSererIdTestnetKey = 'current_node_id_ltc_testnet';
  static const currentHavenNodeIdTestnetKey = 'current_node_id_xhv_testnet';
  static const currentFiatCurrencyKey = 'current_fiat_currency';
  static const currentTransactionPriorityKeyLegacy = 'current_fee_priority';
  static const currentBalanceDisplayModeKey = 'current_balance_display_mode';
  static const shouldSaveRecipientAddressKey = 'save_recipient_address';
  static const currentFiatApiModeKey = 'current_fiat_api_mode';
  static const allowBiometricalAuthenticationKey =
      'allow_biometrical_authentication';
  static const disableExchangeKey = 'disable_exchange';
  static const currentTheme = 'current_theme';
  static const isDarkThemeLegacy = 'dark_theme';
  static const displayActionListModeKey = 'display_list_mode';
  static const currentPinLength = 'current_pin_length';
  static const currentLanguageCode = 'language_code';
  static const currentDefaultSettingsMigrationVersion =
      'current_default_settings_migration_version';
  static const moneroTransactionPriority = 'current_fee_priority_monero';
  static const bitcoinTransactionPriority = 'current_fee_priority_bitcoin';
  static const havenTransactionPriority = 'current_fee_priority_haven';
  static const litecoinTransactionPriority = 'current_fee_priority_litecoin';
  static const shouldShowReceiveWarning = 'should_show_receive_warning';
  static const shouldShowYatPopup = 'should_show_yat_popup';
  static const moneroWalletPasswordUpdateV1Base = 'monero_wallet_update_v1';
  static const pinTimeOutDuration = 'pin_timeout_duration';
  static const lastAuthTimeMilliseconds = 'last_auth_time_milliseconds';
  static const lastPopupDate = 'last_popup_date';


  static String moneroWalletUpdateV1Key(String name)
    => '${PreferencesKey.moneroWalletPasswordUpdateV1Base}_${name}';

  static const exchangeProvidersSelection = 'exchange-providers-selection';
}
