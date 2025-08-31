import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  bool _isLoggedIn = false;
  int _lastScore = 0;
  List<int> _scoreHistory = [];

  String get username => _username;
  bool get isLoggedIn => _isLoggedIn;
  int get lastScore => _lastScore;
  List<int> get scoreHistory => List.unmodifiable(_scoreHistory);

  Future<void> login(String username) async {
    if (username.trim().isNotEmpty) {
      _username = username.trim();
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _username);

      notifyListeners();
    }
  }

  Future<void> logout() async {
    _username = '';
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');

    notifyListeners();
  }

  Future<void> loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    if (savedUsername != null && savedUsername.isNotEmpty) {
      _username = savedUsername;
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<void> saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();

    _lastScore = score;

    final savedList = prefs.getStringList('scores') ?? [];
    _scoreHistory = savedList.map((e) => int.tryParse(e) ?? 0).toList();

    _scoreHistory.add(score);

    await prefs.setStringList(
      'scores',
      _scoreHistory.map((e) => e.toString()).toList(),
    );

    notifyListeners();
  }

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('scores') ?? [];
    _scoreHistory = savedList.map((e) => int.tryParse(e) ?? 0).toList();
    if (_scoreHistory.isNotEmpty) {
      _lastScore = _scoreHistory.last;
    }
    notifyListeners();
  }
}
