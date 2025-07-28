import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:web_labor_contract/API/Controller/User_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
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
        // 1. Cập nhật AuthState
        final authState = Provider.of<AuthState>(context, listen: false);
        await authState.login(userADID);
        
        // // 2. Gọi fetchDataSection ngay sau khi đăng nhập thành công
        // final userController = Provider.of<DashboardControllerUser>(context, listen: false);
        // await userController.fetchDataSection(user: userADID);
              
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String? _adid;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  String? get adid => _adid;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      _adid = await _storage.read(key: 'saved_adid');
      _isAuthenticated = _adid != null;
    } catch (e) {
      print('Error reading secure storage: $e');
      _adid = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String adid) async {
    try {
      await _storage.write(key: 'saved_adid', value: adid);
      _adid = adid;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      print('Error saving to secure storage: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'saved_adid');
      _adid = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      print('Error deleting from secure storage: $e');
      rethrow;
    }
  }
}