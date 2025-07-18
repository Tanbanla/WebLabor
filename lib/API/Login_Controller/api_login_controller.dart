import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/Common/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = Common.API;
  static const String _loginEndpoint = Common.loginEndpoint;
  static const int _timeoutSeconds = 10;

  static Future<Map<String, dynamic>> login({
    required String userADID,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_loginEndpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userADID': userADID, 'password': password}),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] == true) {
          return {
            'success': true,
            'authenticated':
                responseData['data'] == true,
            'message': responseData['message'] ?? 'Login successful',
          };
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ??
                responseData['error'] ??
                'ADID or Passwork is incorrect',
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

// class AuthState extends ChangeNotifier {
//   bool _isAuthenticated = false;

//   bool get isAuthenticated => _isAuthenticated;

//   void login() {
//     _isAuthenticated = true;
//     notifyListeners();
//   }

//   void logout() {
//     _isAuthenticated = false;
//     notifyListeners();
//   }
// }
class AuthState extends ChangeNotifier {
  String? _adid;
  String? get adid => _adid;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String adid) async {
    _adid = adid;
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = true;
    await prefs.setString('saved_adid', adid);
    notifyListeners();
  }

  Future<void> loadSavedAdid() async {
    final prefs = await SharedPreferences.getInstance();
    _adid = prefs.getString('saved_adid');
    notifyListeners();
  }

  Future<void> logout() async {
    _adid = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_adid');
    notifyListeners();
  }
}
