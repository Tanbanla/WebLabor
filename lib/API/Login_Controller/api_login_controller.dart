import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/Common/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_labor_contract/class/User.dart';

class AuthService {
  static String _baseUrl = Common.API;
  static const String _loginEndpoint = Common.AccountLogin; //loginEndpoint;
  static const int _timeoutSeconds = 10;
  static Future<Map<String, dynamic>> login({
    required String userADID,
    required String password,
    required BuildContext context,
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
        if (responseData['success'] == true) {
          // Kiểm tra nếu có dữ liệu user
          if (responseData['data'] != null) {
            final user = User.fromJson(responseData['data']);
            // Lưu thông tin user vào AuthState
            final authState = Provider.of<AuthState>(context, listen: false);
            await authState.login(user);

            return {
              'success': true,
              'message': responseData['message'] ?? 'Login successful',
              'user': user,
            };
          } else {
            return {
              'success': false,
              'message': 'Không tìm thấy thông tin user',
            };
          }
        } else {
          // Trường hợp success = false từ server
          return {
            'success': false,
            'message': responseData['message'] ?? 'Login failed',
          };
        }
      } else {
        // Trường hợp status code không phải 200
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'HTTP error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

class AuthState extends ChangeNotifier {
  static const _keyUser = 'saved_user';
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_keyUser);
      if (userJson != null) {
        _user = User.fromJson(json.decode(userJson));
        _isAuthenticated = true;
      }
    } catch (e) {
      print('Error reading user data: $e');
      _user = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đăng nhập và lưu cả User
  Future<void> login(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, json.encode(user.toJson()));
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
