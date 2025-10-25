import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  Future<void> saveSessionStats(int focusMinutes, int breakMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    int totalFocus = prefs.getInt('totalFocus') ?? 0;
    int totalBreak = prefs.getInt('totalBreak') ?? 0;

    await prefs.setInt('totalFocus', totalFocus + focusMinutes);
    await prefs.setInt('totalBreak', totalBreak + breakMinutes);
  }

  Future<Map<String, int>> loadSessionStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'totalFocus': prefs.getInt('totalFocus') ?? 0,
      'totalBreak': prefs.getInt('totalBreak') ?? 0,
    };
  }

  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('totalFocus');
    await prefs.remove('totalBreak');
  }
}
