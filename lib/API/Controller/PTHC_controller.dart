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
import 'package:web_labor_contract/class/PTHC_Group.dart';
import 'package:web_labor_contract/class/TM_PTHC.dart';
import 'package:web_labor_contract/class/User.dart';

class DashboardControllerPTHC extends GetxController {
  var pthcList = <PthcGroup>[].obs;
  var filteredpthcList = <PthcGroup>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortColumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPTHCData();
  }

  Future<void> fetchPTHCData() async {
    try {
      isLoading(true);
      final response = await http.post(
        Uri.parse(Common.API + Common.GetGroupPTHC),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          pthcList.assignAll(data.map((user) => PthcGroup.fromJson(user)).toList());
          filteredpthcList.assignAll(pthcList);
          selectRows.assignAll(
            List.generate(pthcList.length, (index) => false),
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

    filteredpthcList.sort((a, b) {
      switch (columnIndex) {
        case 0: // ID
          return ascending
              ? (a.section ?? "").compareTo(b.section ?? "")
              : (b.section ?? "").compareTo(a.section ?? "");
        case 1: // User ID
          return ascending
              ? (a.mailto ?? '').compareTo(b.mailto ?? '')
              : (b.mailto ?? '').compareTo(a.mailto ?? '');
        case 2: // Name
          return ascending
              ? (a.mailcc ?? '').compareTo(b.mailcc ?? '')
              : (b.mailcc ?? '').compareTo(a.mailcc ?? '');
        default:
          return 0;
      }
    });
  }

  Future<void> searchQuery(String query) async {
    if (query.isEmpty) {
      filteredpthcList.assignAll(pthcList);
    } else {
      filteredpthcList.assignAll(
        pthcList.where(
          (pthc) =>
              (pthc.section?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (pthc.mailto ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (pthc.mailcc?? '').toLowerCase().contains(
                query.toLowerCase(),
              ),
        ),
      );
    }
  }

  Future<void> updatePTCH(Pthc user, String userUpdate) async {
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
        await fetchPTHCData();
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
        fetchPTHCData();
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${errorResponse['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to add user: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<void> importFromExcel(File file,String userUpdate) async {
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
      await fetchPTHCData();
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
      await fetchPTHCData();
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

  Future<void> deleteUser(int id, {bool logical = true}) async {
    try {
      isLoading(true);
      final endpoint = logical
          ? Common.DeleteIDLogic
          : Common.DeleteID; //logical ? Common.DeleteIDLogic :
      final response = await http.delete(
        // Uri.parse('${Common.API}${Common.DeleteIDLogic}$id'),
        Uri.parse('${Common.API}$endpoint$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchPTHCData();
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
  // Future<void> SendMail(String code, String to, String cc, String bcc) async {
  //   try {
  //     isLoading(true);
  //     final requestBody = {
  //       "master_mail_id": code,
  //       "mail_to": to,
  //       "mail_cc": cc,
  //       "mail_bcc": bcc,
  //     };
  //     final response = await http.post(
  //       Uri.parse(Common.SendMail),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode(requestBody),
  //     );

  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(response.body);
  //       if (jsonData['success'] == true) {
  //         final List<dynamic> data = jsonData['data'];
  //         pthcList.assignAll(data.map((user) => User.fromJson(user)).toList());
  //         filteredpthcList.assignAll(pthcList);
  //         selectRows.assignAll(
  //           List.generate(pthcList.length, (index) => false),
  //         );
  //       }
  //     } else {
  //       throw Exception('Failed to load users');
  //     }
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to fetch data: $e');
  //   } finally {
  //     isLoading(false);
  //   }
  // }
}
