import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  late final SharedPreferences _prefs;

  static const String _dailyReminderKey = 'dailyReminder';
  static const String _professorNoticesKey = 'professorNotices';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get dailyReminder => _prefs.getBool(_dailyReminderKey) ?? true;

  Future<bool> setDailyReminder(bool value) async {
    return await _prefs.setBool(_dailyReminderKey, value);
  }

  bool get professorNotices => _prefs.getBool(_professorNoticesKey) ?? true;

  Future<bool> setProfessorNotices(bool value) async {
    return await _prefs.setBool(_professorNoticesKey, value);
  }

  Future<void> clearUserPreferences() async {
    await _prefs.remove(_dailyReminderKey);
    await _prefs.remove(_professorNoticesKey);
  }
}
