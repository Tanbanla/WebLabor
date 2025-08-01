import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/Apprentice_Contract.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardControllerApprentice extends GetxController {
  var dataList = <ApprenticeContract>[].obs;
  var filterdataList = <ApprenticeContract>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;

  RxString currentStatusId = "1".obs;

  @override
  void onInit() {
    super.onInit();
    //fetchDummyData();
    //fetchDataBy(statusId: currentStatusId.value);
  }

  // Hàm helper để thay đổi status và load lại dữ liệu
  Future<void> changeStatus(
    String newStatusId,
    String? newSection,
    String? adid,
  ) async {
    await fetchDataBy(statusId: newStatusId, section: newSection, adid: adid);
  }

  List<ApprenticeContract> getSelectedItems() {
    List<ApprenticeContract> selectedItems = [];
    for (int i = 0; i < selectRows.length; i++) {
      if (selectRows[i]) {
        selectedItems.add(filterdataList[i]);
      }
    }
    return selectedItems;
  }

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

  // lay du lieu data
  Future<void> fetchDummyData() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse(Common.API + Common.ApprenticeGetAll),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          dataList.assignAll(
            data
                .map((contract) => ApprenticeContract.fromJson(contract))
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

  Future<void> fetchDataBy({
    String? statusId,
    String? section,
    String? adid,
  }) async {
    try {
      isLoading(true);
      if (statusId == null || statusId.isEmpty) {
        throw Exception('Status ID is required');
      }
      isLoading(true);
      String cloumn = "";
      switch (statusId) {
        case "2":
          cloumn = "USER_APPROVER_PER";
          break;
        case "3":
          cloumn = "VCHR_PTHC_SECTION";
          break;
        case "4":
          cloumn = "VCHR_LEADER_EVALUTION";
          break;
        case "5":
          cloumn = "USER_APPROVER_CHIEF";
          break;
        case "6":
          cloumn = "USER_APPROVER_SECTION_MANAGER";
          break;
        case "7":
          cloumn = "USER_APPROVER_DIRECTOR";
          break;
      }
      // Build request body
      final filters = [
        {
          "field": "INT_STATUS_ID",
          "value": statusId,
          "operator": "=",
          "logicType": "AND",
        },
        if (section != null && section.isNotEmpty)
          {
            "field": "VCHR_CODE_SECTION",
            "value": section,
            "operator": "like",
            "logicType": "AND",
          },
        if (adid != null && adid.isNotEmpty)
          {"field": cloumn, "value": adid, "operator": "=", "logicType": "AND"},
      ];

      final requestBody = {
        "pageNumber": -1,
        "pageSize": 10,
        "filters": filters,
      };
      final response = await http.post(
        Uri.parse(Common.API + Common.ApprenticeSreachBy),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // Lấy dữ liệu từ phần data.data (theo cấu trúc response)
          final List<dynamic> data = jsonData['data']['data'] ?? [];

          dataList.assignAll(
            data
                .map((contract) => ApprenticeContract.fromJson(contract))
                .toList(),
          );

          filterdataList.assignAll(dataList);
          selectRows.assignAll(
            List.generate(dataList.length, (index) => false),
          );
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load data');
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

  // api post
  Future<void> addApprenticeContract(
    ApprenticeContract contract,
    String olded,
    String user,
  ) async {
    try {
      isLoading(true);
      // bo sung cac truong con thieu
      contract.id = 0;
      contract.vchRUserCreate = user;
      contract.vchRNameSection = contract.vchRCodeSection;
      contract.dtMCreate = formatDateTime(DateTime.now());
      contract.dtMUpdate = formatDateTime(DateTime.now());
      contract.dtMBrithday = () {
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
      contract.inTStatusId = 1;
      if (contract.vchREmployeeId != null &&
          contract.vchREmployeeId!.isNotEmpty) {
        contract.vchRTyperId = contract.vchREmployeeId!.substring(0, 1);
      } else {
        contract.vchRTyperId = '';
      }
      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddApprentice}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract.toJson()),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update two contract: $e');
    } finally {
      isLoading(false);
    }
  }

  //  update thong tin
  Future<void> updateApprenticeContract(
    ApprenticeContract contract,
    String userUpdate,
  ) async {
    try {
      contract.vchRUserUpdate = userUpdate;
      contract.dtMUpdate = formatDateTime(DateTime.now());

      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdateApprentice}${contract.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract.toJson()),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update two contract: $e');
    } finally {
      isLoading(false);
    }
  }

  //update thong tin to list
  Future<void> updateListApprenticeContract(
    String userApprover,
    String userUpdate,
  ) async {
    try {
      final contract = getSelectedItems();
      if (contract.isEmpty) {
        throw Exception('Lỗi danh sách gửi đi không có dữ liệu!');
      }
      for (int i = 0; i < contract.length; i++) {
        contract[i].vchRUserUpdate = userUpdate;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        contract[i].inTStatusId = 2;
        contract[i].useRApproverPer = userApprover;
        contract[i].vchRCodeApprover =
            'HNTV' + formatDateTime(DateTime.now()).toString();
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListApprentice}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update two contract: $e');
    } finally {
      isLoading(false);
    }
  }

  // update list cho fill
  Future<void> updateListApprenticeContractFill(
    String userApprover,
    String userUpdate,
  ) async {
    try {
      final contract = getSelectedItems();
      if (contract.isEmpty) {
        throw Exception('Lỗi danh sách gửi đi không có dữ liệu!');
      }
      for (int i = 0; i < contract.length; i++) {
        contract[i].vchRUserUpdate = userUpdate;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        if (contract[i].inTStatusId == 3) {
          contract[i].inTStatusId = 4;
          contract[i].nvchRPthcSection = userUpdate;
          contract[i].vchRLeaderEvalution = userApprover;
        } else if (contract[i].inTStatusId == 4) {
          contract[i].inTStatusId = 5;
          contract[i].vchRLeaderEvalution = userUpdate;
          contract[i].useRApproverChief = userApprover;
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListApprentice}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update two contract: $e');
    } finally {
      isLoading(false);
    }
  }

  // delete
  Future<void> deleteApprenticeContract(int id) async {
    try {
      isLoading(true);
      final endpoint = Common.DeleteApprenticeID;
      final response = await http.delete(
        Uri.parse('${Common.API}$endpoint$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ////await fetchDataBy();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete twoContract: $e');
    } finally {
      isLoading(false);
    }
  }

  // import file
  Future<void> importExcelMobileContract(File file, String userUpdate) async {
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
      final List<ApprenticeContract> importedTwoContract = [];
      int _i = 19;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create
        final twocontract = ApprenticeContract()
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
          ..dtMJoinDate = formatDateTime(row[9]?.value?.toString())
          ..dtMEndDate = formatDateTime(row[10]?.value?.toString())
          ..fLGoLeaveLate = row[11]?.value != null
              ? double.tryParse(row[11]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLNotLeaveDay = row[12]?.value != null
              ? double.tryParse(row[12]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..inTViolation = row[13]?.value != null
              ? int.tryParse(row[13]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation // = row[14]!.value.toString()
          ..vchRLyThuyet
          ..vchRThucHanh
          ..vchRCompleteWork
          ..vchRLearnWork
          ..vchRThichNghi
          ..vchRUseful
          ..vchRContact
          ..vcHNeedViolation
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
          ..vchRUserCreate = userUpdate
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
        Uri.parse('${Common.API}${Common.UpdataListApprentice}'),
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
      //await fetchDataBy();
    } catch (e) {
      throw Exception('Import failed: $e');
    } finally {
      isLoading(false);
    }
  }

  // nhap file tren web
  Future<void> importFromExcelWeb(Uint8List bytes, String userUpdate) async {
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
      final List<ApprenticeContract> importedTwoContract = [];
      int _i = 19;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate
        final twocontract = ApprenticeContract()
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
          ..dtMJoinDate = formatDateTime(row[9]?.value?.toString())
          ..dtMEndDate = formatDateTime(row[10]?.value?.toString())
          ..fLGoLeaveLate = row[11]?.value != null
              ? double.tryParse(row[11]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLNotLeaveDay = row[12]?.value != null
              ? double.tryParse(row[12]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..inTViolation = row[13]?.value != null
              ? int.tryParse(row[13]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation //= row[14]!.value.toString()
          ..vchRLyThuyet
          ..vchRThucHanh
          ..vchRCompleteWork
          ..vchRLearnWork
          ..vchRThichNghi
          ..vchRUseful
          ..vchRContact
          ..vcHNeedViolation
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
          ..vchRUserCreate = userUpdate
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
        Uri.parse('${Common.API}${Common.AddListApprentice}'),
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
      //await fetchDataBy();
    } catch (e) {
      throw Exception('Import failed: $e');
    } finally {
      isLoading(false);
    }
  }

  // ham format dateTime
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
