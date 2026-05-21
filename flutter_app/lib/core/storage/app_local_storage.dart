import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorage {
  AppLocalStorage._(this._prefs);

  final SharedPreferences _prefs;

  static const _hasSeenWelcomeKey = 'has_seen_welcome';
  static const _lastMainTabIndexKey = 'last_main_tab_index';
  static const _preferredLocaleKey = 'preferred_locale';
  static const _foodSearchHistoryKey = 'food_search_history';

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
}
