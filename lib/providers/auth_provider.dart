import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final userData = await _db.loginUser(email, password);
      if (userData != null) {
        _user = User(
          id: userData['id'].toString(),
          name: userData['name'],
          email: userData['email'],
        );
        _setLoading(false);
        return true;
      } else {
        _error = 'Invalid email or password';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final userData = await _db.registerUser(email, name, password);
      if (userData != null) {
        _user = User(
          id: userData['id'].toString(),
          name: userData['name'],
          email: userData['email'],
        );
        _setLoading(false);
        return true;
      } else {
        _error = 'Email already exists';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile(User updatedUser) async {
    _setLoading(true);
    _clearError();
    try {
      final success = await _db.updateUser(updatedUser);
      if (success) {
        _user = updatedUser;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void logout() async {
    await _db.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}