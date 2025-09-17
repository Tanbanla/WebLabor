import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:web_labor_contract/class/User.dart';

class DashboardControllerUser extends GetxController {
  var userList = <User>[].obs;
  var filteredUserList = <User>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortColumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchDataSection({String? user}) async {
    try {
      isLoading(true);
      if (user!.isNotEmpty) {
        final requestBody = {
          "pageNumber": -1,
          "pageSize": 10,
          "filters": [
            {
              "field": "CHR_USERID",
              "value": user,
              "operator": "=",
              "logicType": "AND",
            },
          ],
        };
        final response = await http.post(
          Uri.parse(Common.API + Common.UserSreachBy),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData['success'] == true) {
            // Lấy dữ liệu từ phần data.data (theo cấu trúc response)
            final List<dynamic> data = jsonData['data']['data'] ?? [];

            userList.assignAll(
              data.map((contract) => User.fromJson(contract)).toList(),
            );

            filteredUserList.assignAll(userList);
            selectRows.assignAll(
              List.generate(userList.length, (index) => false),
            );
          } else {
            throw Exception(jsonData['message'] ?? 'Failed to load data');
          }
        } else {
          throw Exception('Failed to load Two contract');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchUserData() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse(Common.API + Common.UserGetAll),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          userList.assignAll(data.map((user) => User.fromJson(user)).toList());
          filteredUserList.assignAll(userList);
          selectRows.assignAll(
            List.generate(userList.length, (index) => false),
          );
        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> sortById(int columnIndex, bool ascending) async {
    sortAscending.value = ascending;
    sortColumnIndex.value = columnIndex;

    filteredUserList.sort((a, b) {
      switch (columnIndex) {
        case 0: // ID
          return ascending
              ? (a.id ?? 0).compareTo(b.id ?? 0)
              : (b.id ?? 0).compareTo(a.id ?? 0);
        case 1: // User ID
          return ascending
              ? (a.chRUserid ?? '').compareTo(b.chRUserid ?? '')
              : (b.chRUserid ?? '').compareTo(a.chRUserid ?? '');
        case 2: // Name
          return ascending
              ? (a.nvchRNameId ?? '').compareTo(b.nvchRNameId ?? '')
              : (b.nvchRNameId ?? '').compareTo(a.nvchRNameId ?? '');
        default:
          return 0;
      }
    });
  }

  Future<void> searchQuery(String query) async {
    if (query.isEmpty) {
      filteredUserList.assignAll(userList);
    } else {
      filteredUserList.assignAll(
        userList.where(
          (user) =>
              (user.chRUserid ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (user.nvchRNameId ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (user.chREmployeeId ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ),
        ),
      );
    }
  }

  Future<void> updateUser(User user, String userUpdate) async {
    try {
      isLoading(true);
      user.vchRUserUpdate = userUpdate;
      if (user.vchRUserCreate.toString().isEmpty) {
        user.vchRUserCreate = userUpdate;
      }
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdateUser}${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchUserData();
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${errorResponse['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to update user: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> exportToExcel() async {
    try {
      isLoadingExport(true);
      final response = await http.get(
        Uri.parse('${Common.API}${Common.UserGetAll}?export=excel'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Xử lý file Excel
        Get.snackbar(
          'Success',
          'Exported successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      showError('Export failed: $e');
    } finally {
      isLoadingExport(false);
    }
  }

  // thêm người dùng
  Future<void> addUser(User newUser, String userUpdate) async {
    try {
      isLoading(true);
      final user = User()
        ..id = 0
        ..chRSecCode = null
        ..chREmployeeId = null
        ..nvchRNameId = null
        ..chRUserid = newUser.chRUserid
        ..chRPass = ''
        ..chRGroup = newUser.chRGroup
        ..inTLock = 0
        ..inTLockDay = 90
        ..inTUseridCommon = newUser.inTUseridCommon
        ..vchRUserCreate = userUpdate
        ..dtMCreate = formatDateTime(DateTime.now())
        ..vchRUserUpdate = userUpdate
        ..dtMUpdate = formatDateTime(DateTime.now())
        ..dtMLastLogin = formatDateTime(DateTime.now());
      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddUser}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        fetchUserData();
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
          '${errorResponse['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to add user: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<void> importFromExcel(File file, String userUpdate) async {
    try {
      isLoading(true);
      // Implement your Excel parsing and data import logic here
      // 1. Parse the Excel file
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      // 2. Validate the data
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;
      // 3. Send to API or update local state
      if (rows.isEmpty || rows[0].length < 4) {
        throw Exception('File Excel không đúng định dạng');
      }
      // 4. Refresh data
      final List<User> importedUsers = [];
      int _i = 1;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate user
        final user = User()
          ..id = 0
          ..chRSecCode = row[1]?.value?.toString()
          ..chREmployeeId = row[2]?.value?.toString()
          ..nvchRNameId = row[3]?.value?.toString()
          ..chRUserid = row[4]?.value?.toString()
          ..chRPass = ''
          ..chRGroup = row[5]?.value?.toString()
          ..inTLock =
              (row[7]?.value?.toString() ?? '').toLowerCase() == "delete"
              ? 1
              : 0
          ..inTLockDay = 90
          ..inTUseridCommon =
              (row[6]?.value?.toString() ?? '').toLowerCase() == "dùng chung"
              ? 1
              : 0
          ..vchRUserCreate = userUpdate
          ..dtMCreate = formatDateTime(DateTime.now())
          ..vchRUserUpdate = userUpdate
          ..dtMUpdate = formatDateTime(DateTime.now())
          ..dtMLastLogin = formatDateTime(DateTime.now());

        // Validate required fields
        if (user.chRUserid?.isEmpty == true ||
            user.nvchRNameId?.isEmpty == true ||
            user.chREmployeeId?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }

        importedUsers.add(user);
        _i++;
      }
      // 5. Send to API
      if (importedUsers.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddListUser}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(importedUsers),
      );

      if (response.statusCode != 200) {
        final errorResponse = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${errorResponse['message'] ?? response.body}',
        );
      }

      //6 reset data
      await fetchUserData();
    } catch (e) {
      showError('Import failed: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // add list user web
  Future<void> importFromExcelWeb(Uint8List bytes, String userUpdate) async {
    try {
      isLoading(true);

      // 1. Decode Excel file from bytes
      final excel = Excel.decodeBytes(bytes);

      // 2. Get the first sheet
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;
      // 3. Send to API or update local state
      if (rows.isEmpty || rows[0].length < 4) {
        throw Exception('File Excel không đúng định dạng');
      }
      // 4. Refresh data
      final List<User> importedUsers = [];
      int _i = 1;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate user
        final user = User()
          ..id = 0
          ..chRSecCode = row[1]?.value?.toString()
          ..chREmployeeId = row[2]?.value?.toString()
          ..nvchRNameId = row[3]?.value?.toString()
          ..chRUserid = row[4]?.value?.toString()
          ..chRPass = ''
          ..chRGroup = row[5]?.value?.toString()
          ..inTLock =
              (row[7]?.value?.toString() ?? '').toLowerCase() == "delete"
              ? 1
              : 0
          ..inTLockDay = 90
          ..inTUseridCommon =
              (row[6]?.value?.toString() ?? '').toLowerCase() == "dùng chung"
              ? 1
              : 0
          ..inTUseridCommon = 0
          ..vchRUserCreate = userUpdate
          ..dtMCreate = formatDateTime(DateTime.now())
          ..vchRUserUpdate = userUpdate
          ..dtMUpdate = formatDateTime(DateTime.now())
          ..dtMLastLogin = formatDateTime(DateTime.now());

        // Validate required fields
        if (user.chRUserid?.isEmpty == true ||
            user.nvchRNameId?.isEmpty == true ||
            user.chREmployeeId?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }

        importedUsers.add(user);
        _i++;
      }
      // 5. Send to API
      if (importedUsers.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddListUser}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(importedUsers),
      );

      if (response.statusCode != 200) {
        final errorResponse = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${errorResponse['message'] ?? response.body}',
        );
      }

      //6 reset data
      await fetchUserData();
    } catch (e) {
      showError(
        'Import thất bại: ${e.toString().replaceAll(RegExp(r'^_Namespace:?\s*'), '')}',
      );
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> deleteUser(int id) async {
    try {
      isLoading(true);
      var endpoint = Common.DeleteIDLogic; 
      final index = userList.indexWhere(
        (item) => item.id == id && item.inTLock == 2,
      );
      if (index != -1) {
        endpoint = Common.DeleteID;
      }
      final response = await http.delete(
        // Uri.parse('${Common.API}${Common.DeleteIDLogic}$id'),
        Uri.parse('${Common.API}$endpoint$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchUserData();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to delete user: $e');
    } finally {
      isLoading(false);
    }
  }

  String? formatDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is String) {
      // Try various common datetime formats
      final formats = [
        'yyyy-MM-dd HH:mm:ss.SSS',
        'yyyy-MM-dd HH:mm:ss',
        'yyyy-MM-dd',
      ];

      for (var format in formats) {
        try {
          final date = DateFormat(format).parse(value.replaceAll(' ', ''));
          return date.toIso8601String();
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
  // send mail
  Future<void> SendMail(String code, String to, String cc, String bcc) async {
    try {
      isLoading(true);
      final requestBody = {
        "code_master_mail": code,
        "mail_to": to,
        "mail_cc": cc,
        "mail_bcc": bcc,
      };
      final response = await http.post(
        Uri.parse(Common.SendMail),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // final List<dynamic> data = jsonData['data'];
          // userList.assignAll(data.map((user) => User.fromJson(user)).toList());
          // filteredUserList.assignAll(userList);
          // selectRows.assignAll(
          //   List.generate(userList.length, (index) => false),
          // );
        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }

  // send mail Custom
  Future<void> SendMailCustom(
    String to,
    String cc,
    String bcc,
    List<dynamic> rejectedRequests,
    String loaituchoi,
    String approverNG,
  ) async {
    try {
      isLoading(true);
      final requestBody = {
        "title": "THÔNG BÁO: YÊU CẦU ĐÁNH GIÁ HỢP ĐỒNG BỊ TỪ CHỐI",
        "mail_from": "LaborContractEvaluationSystem@brothergroup.net",
        "mail_to": to == "null" ? "" : to,
        "mail_cc": cc == "null" ? "" : cc,
        "mail_bcc": bcc == "null" ? "" : bcc,
        "body": Common.getRejectionEmailBody(
          confirmLink: "http://172.26.248.62:8055/",
          loaiTuChoi: loaituchoi,
          approverNG: approverNG,
          rejectedRequests: rejectedRequests,
        ),
      };
      final response = await http.post(
        Uri.parse(Common.SendMailCustom),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // final List<dynamic> data = jsonData['data'];
          // userList.assignAll(data.map((user) => User.fromJson(user)).toList());
          // filteredUserList.assignAll(userList);
          // selectRows.assignAll(
          //   List.generate(userList.length, (index) => false),
          // );
        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }
  // send mail KetQua
  Future<void> SendMailKetQua(
    String to,
    String cc,
    String bcc,
    List<dynamic> rejectedRequests,
    String ketquaOld,
    String ketquaNew,
  ) async {
    try {
      isLoading(true);
      final requestBody = {
        "title": "THÔNG BÁO: YÊU CẦU SỬA KẾT QUẢ ĐÁNH GIÁ HỢP ĐỒNG ĐÃ HOÀN THÀNH<br/>件名：通知：完了した契約評価結果の修正依頼",
        "mail_from": "LaborContractEvaluationSystem@brothergroup.net",
        "mail_to": to == "null" ? "" : to,
        "mail_cc": cc == "null" ? "" : cc,
        "mail_bcc": bcc == "null" ? "" : bcc,
        "body": Common.getKetQuaEmailBody(
          confirmLink: "http://172.26.248.62:8055/",
          ketquaOld: ketquaOld,
          ketquaNew: ketquaNew,
          rejectedRequests: rejectedRequests,
        ),
      };
      final response = await http.post(
        Uri.parse(Common.SendMailCustom),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {

        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }
}
