import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final APIService _api = APIService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Login handler
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      }, includeAuth: false);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyAccessToken, body['access_token']);
        await prefs.setString(AppConstants.keyRefreshToken, body['refresh_token']);
        
        _currentUser = User(
          id: body['user_id'] ?? 0,
          name: body['full_name'] ?? '',
          email: email,
          role: body['role'] ?? '',
        );

        await prefs.setString(AppConstants.keyUserData, jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        _errorMessage = errorBody['detail'] ?? 'Login failed. Please check your credentials.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Connection failed.';
      _setLoading(false);
      return false;
    }
  }

  // Register user handler
  Future<bool> register(String name, String email, String password, String role) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _api.post('/auth/register', {
        'email': email,
        'password': password,
        'full_name': name,
        'role': role,
      }, includeAuth: false);

      if (response.statusCode == 201) {
        _setLoading(false);
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        _errorMessage = errorBody['detail'] ?? 'Registration failed.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection timeout. Try again later.';
      _setLoading(false);
      return false;
    }
  }

  // Auto Login Check
  Future<bool> checkAutoLogin() async {
    _isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(AppConstants.keyAccessToken);
    
    if (accessToken == null) {
      _isLoading = false;
      return false;
    }

    try {
      final response = await _api.get('/auth/me');
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _currentUser = User.fromJson(body);
        await prefs.setString(AppConstants.keyUserData, jsonEncode(_currentUser!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Access token expired, try refreshing
        final refreshed = await _api.refreshSessionToken();
        if (refreshed) {
          final retryResponse = await _api.get('/auth/me');
          if (retryResponse.statusCode == 200) {
            final body = jsonDecode(retryResponse.body);
            _currentUser = User.fromJson(body);
            await prefs.setString(AppConstants.keyUserData, jsonEncode(_currentUser!.toJson()));
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      // Offline fallback: Use cached local user profile if available
      final userString = prefs.getString(AppConstants.keyUserData);
      if (userString != null) {
        _currentUser = User.fromJson(jsonDecode(userString));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    // Force signout if all credentials stale
    await logout();
    _isLoading = false;
    return false;
  }

  // Logout routine
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUserData);
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
