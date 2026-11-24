import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/models.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;
  static const _key = 'jwt';

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  Future<void> init() async {
    _api.onUnauthorized = _onUnauthorized;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _api.token = saved;
    try {
      user = await _api.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      _api.token = null;
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    final r = await _api.login(identifier, password);
    _api.token = r.token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, r.token);
    user = r.user;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _clear();
  }

  Future<void> updateProfile({required String firstName, required String lastName, required String username}) async {
    user = await _api.updateProfile(firstName: firstName, lastName: lastName, username: username);
    notifyListeners();
  }

  void _onUnauthorized() {
    if (status == AuthStatus.authenticated) _clear();
  }

  Future<void> _clear() async {
    _api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
