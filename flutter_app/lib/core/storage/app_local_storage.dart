import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorage {
  AppLocalStorage._(this._prefs);

  final SharedPreferences _prefs;

  static const _hasSeenWelcomeKey = 'has_seen_welcome';
  static const _lastMainTabIndexKey = 'last_main_tab_index';
  static const _preferredLocaleKey = 'preferred_locale';
  static const _foodSearchHistoryKey = 'food_search_history';
  static const _notificationPermissionGrantedKey = 'notification_permission_granted';
  static const _waterRemindersKey = 'water_reminders_enabled';
  static const _mealRemindersKey = 'meal_reminders_enabled';
  static const _fastingNotificationsKey = 'fasting_notifications_enabled';
  static const _dailySummaryKey = 'daily_summary_enabled';
  static const _premiumSubscriptionKey = 'premium_subscription_state';

  static Future<AppLocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLocalStorage._(prefs);
  }

  bool get hasSeenWelcome => _prefs.getBool(_hasSeenWelcomeKey) ?? false;

  Future<void> setHasSeenWelcome(bool value) => _prefs.setBool(_hasSeenWelcomeKey, value);

  int get lastMainTabIndex => _prefs.getInt(_lastMainTabIndexKey) ?? 0;

  Future<void> setLastMainTabIndex(int value) => _prefs.setInt(_lastMainTabIndexKey, value);

  String? get preferredLocale => _prefs.getString(_preferredLocaleKey);

  Future<void> setPreferredLocale(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_preferredLocaleKey);
      return;
    }

    await _prefs.setString(_preferredLocaleKey, value);
  }

  List<String> get foodSearchHistory => _prefs.getStringList(_foodSearchHistoryKey) ?? const [];

  Future<void> setFoodSearchHistory(List<String> values) async {
    await _prefs.setStringList(_foodSearchHistoryKey, values);
  }

  bool get notificationPermissionGranted => _prefs.getBool(_notificationPermissionGrantedKey) ?? false;
  bool get waterRemindersEnabled => _prefs.getBool(_waterRemindersKey) ?? true;
  bool get mealRemindersEnabled => _prefs.getBool(_mealRemindersKey) ?? true;
  bool get fastingNotificationsEnabled => _prefs.getBool(_fastingNotificationsKey) ?? true;
  bool get dailySummaryEnabled => _prefs.getBool(_dailySummaryKey) ?? true;

  Future<void> setNotificationPermissionGranted(bool value) => _prefs.setBool(_notificationPermissionGrantedKey, value);
  Future<void> setWaterRemindersEnabled(bool value) => _prefs.setBool(_waterRemindersKey, value);
  Future<void> setMealRemindersEnabled(bool value) => _prefs.setBool(_mealRemindersKey, value);
  Future<void> setFastingNotificationsEnabled(bool value) => _prefs.setBool(_fastingNotificationsKey, value);
  Future<void> setDailySummaryEnabled(bool value) => _prefs.setBool(_dailySummaryKey, value);

  String? get premiumSubscriptionStateJson => _prefs.getString(_premiumSubscriptionKey);

  Future<void> setPremiumSubscriptionStateJson(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_premiumSubscriptionKey);
      return;
    }

    await _prefs.setString(_premiumSubscriptionKey, value);
  }

  Future<void> setPremiumSubscriptionState(Map<String, dynamic> value) =>
      setPremiumSubscriptionStateJson(jsonEncode(value));
}
