import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/Two_Contract.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardControllerTwo extends GetxController {
  var dataList = <TwoContract>[].obs;
  var filterdataList = <TwoContract>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDummyData();
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

  List<TwoContract> getSelectedItems() {
    List<TwoContract> selectedItems = [];
    for (int i = 0; i < selectRows.length; i++) {
      if (selectRows[i]) {
        selectedItems.add(filterdataList[i]);
      }
    }
    return selectedItems;
  }

  //sap xep du lieu
  void sortById(int sortColumnIndex, bool ascending) {
    sortAscending.value = ascending;
    sortCloumnIndex.value = sortColumnIndex;

    dataList.sort((a, b) {
      switch (sortColumnIndex) {
        case 0: // ID
          return ascending
              ? (a.id ?? 0).compareTo(b.id ?? 0)
              : (b.id ?? 0).compareTo(a.id ?? 0);
        case 1: // employee ID
          return ascending
              ? (a.vchREmployeeId ?? '').compareTo(b.vchREmployeeId ?? '')
              : (b.vchREmployeeId ?? '').compareTo(a.vchREmployeeId ?? '');
        case 2: // Name
          return ascending
              ? (a.vchREmployeeName ?? '').compareTo(b.vchREmployeeName ?? '')
              : (b.vchREmployeeName ?? '').compareTo(a.vchREmployeeName ?? '');
        default:
          return 0;
      }
    });
  }

  // so sanh du lieu
  void searchQuery(String query) {
    if (query.isEmpty) {
      filterdataList.assignAll(dataList);
    } else {
      filterdataList.assignAll(
        dataList.where(
          (item) =>
              (item.vchREmployeeId?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false) ||
              (item.vchREmployeeName?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false) ||
              (item.vchRNameSection?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false),
        ),
      );
    }
  }

  // lay du lieu
  Future<void> fetchDummyData() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse(Common.API + Common.TwoGetAll),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          dataList.assignAll(
            data
                .map((twocontract) => TwoContract.fromJson(twocontract))
                .toList(),
          );
          filterdataList.assignAll(dataList);
          selectRows.assignAll(
            List.generate(dataList.length, (index) => false),
          );
        }
      } else {
        throw Exception('Failed to load Two contract');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }

  // them danh gia
  Future<void> addTwoContract(TwoContract twocontract, String olded) async {
    try {
      // bo sung cac truong con thieu
      twocontract.id = 0;
      twocontract.vchRUserCreate = 'khanhmf';
      twocontract.vchRNameSection = twocontract.vchRCodeSection;
      twocontract.dtMCreate = formatDateTime(DateTime.now());
      twocontract.dtMUpdate = formatDateTime(DateTime.now());
      twocontract.dtMBrithday = () {
        try {
          final age = int.tryParse(olded) ?? 0;
          final birthDate = DateTime(
            DateTime.now().year - age,
            DateTime.now().month,
            DateTime.now().day,
          );
          return birthDate.toIso8601String();
        } catch (e) {
          return null; // hoặc giá trị mặc định nếu cần
        }
      }();
      twocontract.inTStatusId = 1;
      if (twocontract.vchREmployeeId != null &&
          twocontract.vchREmployeeId!.isNotEmpty) {
        twocontract.vchRTyperId = twocontract.vchREmployeeId!.substring(0, 1);
      } else {
        twocontract.vchRTyperId = '';
      }

      isLoading(true);
      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract.toJson()),
      );
      if (response.statusCode == 200) {
        await fetchDummyData();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // update thông tin
  Future<void> updateTwoContract(TwoContract twocontract) async {
    try {
      twocontract.vchRUserUpdate = 'khanhmf';
      twocontract.dtMUpdate = formatDateTime(DateTime.now());

      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdateTwo}${twocontract.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract.toJson()),
      );
      if (response.statusCode == 200) {
        await fetchDummyData();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // udpate to list
  Future<void> updateListTwoContract(
    String userApprover,
  ) async {
    try {
         // List<TwoContract> twocontract,
      final twocontract = getSelectedItems();
      if (twocontract.isEmpty) {
        throw Exception('Lỗi danh sách gửi đi không có dữ liệu!');
      }
      for (int i = 0; i < twocontract.length; i++){
        twocontract[i].vchRUserUpdate = 'khanhmf';
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        twocontract[i].inTStatusId = 2;
        twocontract[i].useRApproverPer = userApprover;
      }
        isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract),
      );
      if (response.statusCode == 200) {
        await fetchDummyData();
      } else {
        final error = json.decode(response.body);
        print(json.encode(twocontract));
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${userApprover}',
        );
      }
    } catch (e) {
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // delete
  Future<void> deleteTwoContract(int id) async {
    try {
      isLoading(true);
      final endpoint = Common.DeleteTwoID;
      final response = await http.delete(
        Uri.parse('${Common.API}$endpoint$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchDummyData();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to delete twoContract: $e');
    } finally {
      isLoading(false);
    }
  }

  // xuat file
  Future<void> exportToExcelTwoContract() async {
    try {
      isLoadingExport(true);
      final response = await http.get(
        Uri.parse('${Common.API}${Common.TwoGetAll}?export=excel'),
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
      rethrow;
    } finally {
      isLoadingExport(false);
    }
  }

  // import file
  Future<void> importExcelMobileTwoContract(File file) async {
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
      final List<TwoContract> importedTwoContract = [];
      int _i = 19;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate twoContract
        final twocontract = TwoContract()
          ..id = 0
          ..vchRCodeApprover
          //'HD2N' + formatDateTime(DateTime.now()).toString()
          ..vchRCodeSection = row[4]?.value?.toString()
          ..vchRNameSection = row[4]?.value?.toString()
          ..vchREmployeeId = row[1]?.value?.toString()
          ..vchRTyperId = row[2]?.value?.toString()
          ..vchREmployeeName = row[3]?.value?.toString()
          ..dtMBrithday = () {
            try {
              final age = int.tryParse(row[6]?.value?.toString() ?? '0') ?? 0;
              final birthDate = DateTime(
                DateTime.now().year - age,
                DateTime.now().month,
                DateTime.now().day,
              );
              return birthDate.toIso8601String();
            } catch (e) {
              return null; // hoặc giá trị mặc định nếu cần
            }
          }()
          ..chRPosition = row[7]?.value?.toString()
          ..chRCodeGrade = row[8]?.value?.toString()
          ..chRCostCenterName = row[5]?.value?.toString()
          ..dtMJoinDate = row[9]?.value?.toString()
          ..dtMEndDate = row[10]?.value?.toString()
          ..fLGoLeaveLate = row[11]?.value != null
              ? double.tryParse(row[11]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLPaidLeave = row[12]?.value != null
              ? double.tryParse(row[12]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..fLNotPaidLeave = row[13]?.value != null
              ? double.tryParse(row[13]!.value.toString()) ?? 0
              : 0 //double.parse(row[13]!.value.toString())
          ..fLNotLeaveDay = row[14]?.value != null
              ? double.tryParse(row[14]!.value.toString()) ?? 0
              : 0 //double.parse(row[14]!.value.toString())
          ..inTViolation = row[15]?.value != null
              ? int.tryParse(row[15]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation = row[16]!.value.toString()
          ..nvarchaRHealthResults
          ..vchRReasultsLeader
          ..biTNoReEmployment
          ..nvchRNoReEmpoyment
          ..nvchRPthcSection
          ..vchRLeaderEvalution
          ..dtMLeadaerEvalution
          ..biTApproverPer
          ..nvchRApproverPer
          ..dtMApproverPer
          ..biTApproverPer
          ..nvchRApproverChief
          ..dtMApproverChief
          ..biTApproverSectionManager
          ..nvchRApproverManager
          ..dtMApproverManager
          ..biTApproverDirector
          ..nvchRApproverDirector
          ..dtMApproverDirector
          ..vchRUserCreate = 'khanhmf'
          ..dtMCreate = formatDateTime(DateTime.now())
          ..vchRUserUpdate = ''
          ..dtMUpdate = formatDateTime(DateTime.now())
          ..inTStatusId = 1
          ..vchRNote
          ..useRApproverPer
          ..useRApproverChief
          ..useRApproverSectionManager
          ..useRApproverDirector;
        // Validate required fields
        if (twocontract.vchREmployeeId?.isEmpty == true ||
            twocontract.vchREmployeeName?.isEmpty == true ||
            twocontract.vchRCodeSection?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }

        importedTwoContract.add(twocontract);
        _i++;
      }
      // 5. Send to API
      if (importedTwoContract.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.UpdataListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(importedTwoContract),
      );

      if (response.statusCode != 200) {
        final errorResponse = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${errorResponse['message'] ?? response.body}',
        );
      }
      //6 reset data
      await fetchDummyData();
    } catch (e) {
      showError('Import failed: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // nhap file tren web
  Future<void> importFromExcelWeb(Uint8List bytes) async {
    try {
      isLoading(true);
      // Implement your Excel parsing and data import logic here
      // 1. Parse the Excel file
      final excel = Excel.decodeBytes(bytes);
      // 2. Validate the data
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;
      // 3. Send to API or update local state
      if (rows.isEmpty || rows[0].length < 4) {
        throw Exception('File Excel không đúng định dạng');
      }
      // 4. Refresh data
      final List<TwoContract> importedTwoContract = [];
      int _i = 19;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate
        final twocontract = TwoContract()
          ..id = 0
          ..vchRCodeApprover //=
          //'HD2N' + formatDateTime(DateTime.now()).toString()
          ..vchRCodeSection = row[4]?.value?.toString()
          ..vchRNameSection = row[4]?.value?.toString()
          ..vchREmployeeId = row[1]?.value?.toString()
          ..vchRTyperId = row[2]?.value?.toString()
          ..vchREmployeeName = row[3]?.value?.toString()
          ..dtMBrithday
          ..dtMBrithday = () {
            try {
              final age = int.tryParse(row[6]?.value?.toString() ?? '0') ?? 0;
              final birthDate = DateTime(
                DateTime.now().year - age,
                DateTime.now().month,
                DateTime.now().day,
              );
              return birthDate.toIso8601String();
            } catch (e) {
              return null; // hoặc giá trị mặc định nếu cần
            }
          }()
          ..chRPosition = row[7]?.value?.toString()
          ..chRCodeGrade = row[8]?.value?.toString()
          ..chRCostCenterName = row[5]?.value?.toString()
          ..dtMJoinDate = row[9]?.value?.toString()
          ..dtMEndDate = row[10]?.value?.toString()
          ..fLGoLeaveLate = row[11]?.value != null
              ? double.tryParse(row[11]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLPaidLeave = row[12]?.value != null
              ? double.tryParse(row[12]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..fLNotPaidLeave = row[13]?.value != null
              ? double.tryParse(row[13]!.value.toString()) ?? 0
              : 0 //double.parse(row[13]!.value.toString())
          ..fLNotLeaveDay = row[14]?.value != null
              ? double.tryParse(row[14]!.value.toString()) ?? 0
              : 0 //double.parse(row[14]!.value.toString())
          ..inTViolation = row[15]?.value != null
              ? int.tryParse(row[15]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation = row[16]!.value.toString()
          ..nvarchaRHealthResults
          ..vchRReasultsLeader
          ..biTNoReEmployment
          ..nvchRNoReEmpoyment
          ..nvchRPthcSection
          ..vchRLeaderEvalution
          ..dtMLeadaerEvalution
          ..biTApproverPer
          ..nvchRApproverPer
          ..dtMApproverPer
          ..biTApproverPer
          ..nvchRApproverChief
          ..dtMApproverChief
          ..biTApproverSectionManager
          ..nvchRApproverManager
          ..dtMApproverManager
          ..biTApproverDirector
          ..nvchRApproverDirector
          ..dtMApproverDirector
          ..vchRUserCreate = 'khanhmf'
          ..dtMCreate = formatDateTime(DateTime.now())
          ..vchRUserUpdate = ''
          ..dtMUpdate = formatDateTime(DateTime.now())
          ..inTStatusId = 1
          ..vchRNote
          ..useRApproverPer
          ..useRApproverChief
          ..useRApproverSectionManager
          ..useRApproverDirector;
        // Validate required fields
        if (twocontract.vchREmployeeId?.isEmpty == true ||
            twocontract.vchREmployeeName?.isEmpty == true ||
            twocontract.vchRCodeSection?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }

        importedTwoContract.add(twocontract);
        _i++;
      }
      // 5. Send to API
      if (importedTwoContract.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(importedTwoContract),
      );

      if (response.statusCode != 200) {
        final errorResponse = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${errorResponse['message'] ?? response.body}',
        );
      }
      //6 reset data
      await fetchDummyData();
    } catch (e) {
      showError('Import failed: $e');
      rethrow;
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
