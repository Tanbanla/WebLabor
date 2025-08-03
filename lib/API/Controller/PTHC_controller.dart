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
        Uri.parse('${Common.API}${Common.UpdatePTHC}${user.id}'),
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
      showError('Failed to update PTHC: $e');
    } finally {
      isLoading(false);
    }
  }

  // thêm người dùng
  Future<void> addPTHC(Pthc newPthc, String userUpdate) async {
    try {
      isLoading(true);
      final pthc = Pthc()
        ..id = 0
        ..vchRCodeSection = newPthc.vchRCodeSection
        ..vchRNameSection = newPthc.vchRNameSection
        ..vchREmployeeId = newPthc.vchREmployeeId
        ..nvchREmployeeName = newPthc.nvchREmployeeName
        ..vchREmployeeAdid = newPthc.vchREmployeeAdid
        ..vchRMail = newPthc.vchRMail
        ..vchRUserCreate = userUpdate
        ..dtMCreate = formatDateTime(DateTime.now())
        ..vchRUserUpdate = userUpdate
        ..dtMUpdate = formatDateTime(DateTime.now())
        ..inTStatusId = newPthc.inTStatusId
        ..vchRNote = newPthc.vchRNote;
      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddPTHC}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(pthc.toJson()),
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
      showError('Failed to add PTHC: $e');
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
      final List<Pthc> importedPTHC = [];
      int _i = 1;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate pthc
        final pthc = Pthc()
        ..id = 0
        ..vchRCodeSection = row[1]?.value?.toString()
        ..vchRNameSection = row[1]?.value?.toString()
        ..vchREmployeeId = row[2]?.value?.toString()
        ..nvchREmployeeName = row[3]?.value?.toString()
        ..vchREmployeeAdid = row[4]?.value?.toString()
        ..vchRMail = row[5]?.value?.toString()
        ..vchRUserCreate = userUpdate
        ..dtMCreate = formatDateTime(DateTime.now())
        ..vchRUserUpdate = userUpdate
        ..dtMUpdate = formatDateTime(DateTime.now())
        ..inTStatusId = 1
        ..vchRNote ="Update by file";

        // Validate required fields
        if (pthc.vchREmployeeAdid?.isEmpty == true ||
            pthc.vchREmployeeId?.isEmpty == true ||
            pthc.vchRMail?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }

        importedPTHC.add(pthc);
        _i++;
      }
      // 5. Send to API
      if (importedPTHC.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddListPTHC}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(importedPTHC),
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
      final List<Pthc> importedPTHC = [];
      int _i = 1;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate user
        final pthc = Pthc()
        ..id = 0
        ..vchRCodeSection = row[1]?.value?.toString()
        ..vchRNameSection = row[1]?.value?.toString()
        ..vchREmployeeId = row[2]?.value?.toString()
        ..nvchREmployeeName = row[3]?.value?.toString()
        ..vchREmployeeAdid = row[4]?.value?.toString()
        ..vchRMail = row[5]?.value?.toString()
        ..vchRUserCreate = userUpdate
        ..dtMCreate = formatDateTime(DateTime.now())
        ..vchRUserUpdate = userUpdate
        ..dtMUpdate = formatDateTime(DateTime.now())
        ..inTStatusId = 1
        ..vchRNote ="Update by file";

        // Validate required fields
        if (pthc.vchREmployeeAdid?.isEmpty == true ||
            pthc.vchREmployeeId?.isEmpty == true ||
            pthc.vchRMail?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }

        importedPTHC.add(pthc);
        _i++;
      }
      // 5. Send to API
      if (importedPTHC.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddListPTHC}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(importedPTHC),
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

  Future<void> deletePTHC(int id, {bool logical = true}) async {
    try {
      isLoading(true);
      final endpoint = logical
          ? Common.DeletePTHCIDLogic
          : Common.DeletePTHCID; //logical ? Common.DeleteIDLogic :
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
      showError('Failed to delete PTHC: $e');
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
}
