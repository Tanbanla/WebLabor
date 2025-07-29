import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/Common/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_labor_contract/class/User.dart';

class AuthService {
  static const String _baseUrl = Common.API;
  static const String _loginEndpoint = Common.loginEndpoint;
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
        if (responseData['data'] == true) {
          // Cập nhật AuthState khi đăng nhập thành công
          // final authState = Provider.of<AuthState>(context, listen: false);
          // await authState.login(userADID);

          final requestBody = {
            "pageNumber": -1,
            "pageSize": 10,
            "filters": [
              {
                "field": "CHR_USERID",
                "value": userADID,
                "operator": "=",
                "logicType": "AND",
              },
            ],
          };
          final response1 = await http.post(
            Uri.parse(Common.API + Common.UserSreachBy),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          );

          if (response1.statusCode == 200) {
            final jsonData = json.decode(response1.body);
            if (jsonData['success'] == true) {
              // Lấy dữ liệu từ phần data.data (theo cấu trúc response)
              final List<dynamic> data = jsonData['data']['data'] ?? [];
              if (data.isEmpty) {
                return {
                  'success': false,
                  'message': 'Không tìm thấy thông tin user',
                };
              }
              final user = User.fromJson(data[0]);
              // Lưu thông tin user vào AuthState
              final authState = Provider.of<AuthState>(context, listen: false);
              await authState.login(user);
            } else {
              return {
                'success': false,
                'message': jsonData['message'] ?? 'Failed to load data',
              };
            }
          } else {
            return {'success': false, 'message': 'Login failed data null'};
          }
          return {
            'success': true,
            'message': responseData['message'] ?? 'Login successful',
          };
        }
      }
      return {
        'success': false,
        'message': responseData['message'] ?? 'Login failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

class AuthState extends ChangeNotifier {
  static const _keyUser = 'saved_user'; // Thay _keyAdid bằng _keyUser
  User? _user; // Thay _adid bằng _user
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
        _user = User.fromJson(json.decode(userJson)); // Chuyển JSON thành User
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
      await prefs.setString(
        _keyUser,
        json.encode(user.toJson()), // Chuyển User thành JSON
      );
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
