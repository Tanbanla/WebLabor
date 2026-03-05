import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_labor_contract/API/Controller/User_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/Apprentice_Contract.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_labor_contract/class/PTHC_Group.dart';
import 'package:web_labor_contract/class/User_Approver.dart';

class DashboardControllerApprentice extends GetxController {
  var dataList = <ApprenticeContract>[].obs;
  var filterdataList = <ApprenticeContract>[].obs;
  var originalList = <ApprenticeContract>[].obs;
  var listSection = <String>[].obs;
  var selectedStatus = ''.obs;
  // Multi-field query holders (new)
  final approverCodeQuery = ''.obs;
  final employeeIdQuery = ''.obs;
  final employeeNameQuery = ''.obs;
  final departmentQuery = ''.obs;
  final groupQuery = ''.obs;
  final dueDateQuery = ''.obs;
  // =========== Server side pagination state ===========
  final currentPage = 1.obs; // pageIndex from API (1-based)
  final pageSize = 50.obs; // pageSize used in request
  final totalPages = 0.obs; // totalPages from API
  final totalCount = 0.obs; // totalCount from API
  // =====================================================
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;
  var pthcList = <PthcGroup>[].obs;

  RxString currentStatusId = "1".obs;
  // Lưu trữ file lỗi import để có thể tải xuống giao diện
  Rx<Uint8List?> lastImportErrorExcel = Rx<Uint8List?>(null);
  // Danh sách thông báo lỗi từng dòng
  RxList<String> lastImportErrors = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    //fetchDummyData();
    //fetchDataBy(statusId: currentStatusId.value);
  }

  // Build filters for server-side search based on current UI state
  List<Map<String, dynamic>> _buildServerFilters(
    String chucVu, {
    String? section,
  }) {
    final List<Map<String, dynamic>> filters = [];
    // Status filter
    if (selectedStatus.value.isEmpty || selectedStatus.value == 'all') {
      filters.add({
        "field": "INT_STATUS_ID",
        "value": "",
        "operator": "is Not Null",
        "logicType": "AND",
      });
    } else if (selectedStatus.value == 'Not Done') {
      // Not Done = status != 9 (backend may not support !=; fallback to IN of all except 9)
      filters.add({
        "field": "INT_STATUS_ID",
        "value": [1, 2, 3, 4, 5, 6, 7, 8],
        "operator": "IN",
        "logicType": "AND",
      });
    } else {
      filters.add({
        "field": "INT_STATUS_ID",
        "value": _mapStatusToId(selectedStatus.value),
        "operator": "=",
        "logicType": "AND",
      });
    }

    // Text filters (LIKE)
    if (approverCodeQuery.value.isNotEmpty) {
      filters.add({
        "field": "VCHR_CODE_APPROVER",
        "value": "%${approverCodeQuery.value}%",
        "operator": "LIKE",
        "logicType": "AND",
      });
    }
    if (employeeIdQuery.value.isNotEmpty) {
      filters.add({
        "field": "VCHR_EMPLOYEE_ID",
        "value": "%${employeeIdQuery.value}%",
        "operator": "LIKE",
        "logicType": "AND",
      });
    }
    if (employeeNameQuery.value.isNotEmpty) {
      filters.add({
        "field": "VCHR_EMPLOYEE_NAME",
        "value": "%${employeeNameQuery.value}%",
        "operator": "LIKE",
        "logicType": "AND",
      });
    }
    //----------------- trường hợp là quản lý các phòng ban --------------------\\
    switch (chucVu) {
      case "PTHC":
      case "Section Manager":
        // Lọc theo section thông qua search
        List<String> sectionValues;
        final trimmed = section == null ? "" : section.trim();
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          try {
            final decoded = json.decode(trimmed);
            if (decoded is List) {
              sectionValues = decoded.map((e) => e.toString().trim()).toList();
            } else {
              sectionValues = [trimmed];
            }
          } catch (_) {
            sectionValues = [trimmed];
          }
        } else {
          sectionValues = [trimmed];
        }
        // chọn có trong phòng ban không
        // final checkS = sectionValues
        //     .where((element) => element == departmentQuery.value)
        //     .toList();
        if (departmentQuery.value.isNotEmpty) {
          //&& checkS.isNotEmpty) {
          filters.add({
            "field": "VCHR_CODE_SECTION",
            "value": "%${departmentQuery.value}%",
            "operator": "LIKE",
            "logicType": "AND",
          });
          break;
        } else {
          filters.add({
            "field": "VCHR_CODE_SECTION",
            "value": sectionValues,
            "operator": "IN",
            "logicType": "AND",
          });
          break;
        }
      case "Dept":
      case "Dept Manager":
        if (departmentQuery.value.isNotEmpty) {
          filters.add({
            "field": "VCHR_CODE_SECTION",
            "value": "%${departmentQuery.value}%",
            "operator": "LIKE",
            "logicType": "AND",
          });
          break;
        }
        filters.add({
          "field": "VCHR_CODE_SECTION",
          "value": "%$section%",
          "operator": "LIKE",
          "logicType": "AND",
        });
        break;
      case "Director":
      case "General Director":
        if (section == null || section.isEmpty) {
          throw Exception('Section is required for Director role');
        }
        if (departmentQuery.value.isNotEmpty) {
          filters.add({
            "field": "VCHR_CODE_SECTION",
            "value": "%${departmentQuery.value}%",
            "operator": "LIKE",
            "logicType": "AND",
          });
          break;
        }
        List<String> sectionValues = section.split(",");
        for (var a in sectionValues) {
          filters.add({
            "field": "VCHR_CODE_SECTION",
            "value": '%${a.trim()}%',
            "operator": "LIKE",
            "logicType": "OR",
          });
        }
        break;
      default:
        if (departmentQuery.value.isNotEmpty) {
          filters.add({
            "field": "VCHR_CODE_SECTION",
            "value": "%${departmentQuery.value}%",
            "operator": "LIKE",
            "logicType": "AND",
          });
        }
        break;
    }
    if (groupQuery.value.isNotEmpty) {
      filters.add({
        "field": "CHR_COST_CENTER_NAME",
        "value": "%${groupQuery.value}%",
        "operator": "LIKE",
        "logicType": "AND",
      });
    }
    return filters;
  }

  dynamic _mapStatusToId(String status) {
    switch (status) {
      case 'New':
        return 1;
      case 'Per':
      case 'Per/人事課の中級管理職':
        return 2;
      case 'PTHC':
        return 3;
      case 'Leader':
        return 4;
      case 'Chief':
        return 5;
      case 'QLTC':
      case 'QLTC/中級管理職':
        return 6;
      case 'QLCC':
      case 'QLCC/上級管理職':
        return 7;
      case 'Director':
      case 'Director/管掌取締役':
        return 8;
      case 'Done':
        return 9;
      default:
        return 1;
    }
  }

  // Server-side pagination & filtering fetch
  Future<void> fetchPagedApprenticeContracts({
    int? page,
    int? size,
    String? chucVu,
    String? section,
  }) async {
    try {
      isLoading(true);
      if (page != null) currentPage.value = page;
      if (size != null) pageSize.value = size;
      final body = {
        "pageNumber": currentPage.value,
        "pageSize": pageSize.value,
        "filters": _buildServerFilters(chucVu ?? '', section: section),
        "sortOptions": [
          {"field": "DTM_CREATE", "sortDirection": "desc"},
        ],
      };
      print('fetchDummyData request: ${json.encode(body)}');
      final response = await http.post(
        Uri.parse(Common.API + Common.ApprenticeSreachBy),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final dataObj = jsonData['data'] ?? {};
          totalPages.value = dataObj['totalPages'] ?? 0;
          totalCount.value = dataObj['totalFilter'] ?? 0;
          pageSize.value = dataObj['pageSize'] ?? pageSize.value;
          currentPage.value = dataObj['pageIndex'] ?? currentPage.value;
          final List<dynamic> rows = dataObj['data'] ?? [];
          dataList.assignAll(
            rows.map((e) => ApprenticeContract.fromJson(e)).toList(),
          );
          filterdataList.assignAll(dataList); // current page data
          selectRows.assignAll(
            List.generate(filterdataList.length, (_) => false),
          );
        } else {
          throw Exception(jsonData['message'] ?? 'Fetch failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch paged data: $e');
    } finally {
      isLoading(false);
    }
  }

  ApprenticeContract? _byEmp(String employeeCode) {
    try {
      return filterdataList.firstWhere((e) => e.vchREmployeeId == employeeCode);
    } catch (_) {
      return null;
    }
  }

  // Hàm helper để thay đổi status và load lại dữ liệu
  Future<void> changeStatus(
    String newStatusId,
    String? newSection,
    String? adid,
    String? chucVu,
  ) async {
    await fetchDataBy(
      statusId: newStatusId,
      section: newSection,
      adid: adid,
      chucVu: chucVu,
    );
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

  // ==================== NEW COMBINED FILTER SYSTEM ====================
  // Public entry points used by the UI. Each update triggers applyFilters().
  void updateStatus(String? value) {
    selectedStatus.value = value ?? '';
    applyFilters();
  }

  void updateApproverCode(String v) {
    approverCodeQuery.value = v.trim();
    applyFilters();
  }

  // due date filter
  void updateDueDate(String v) {
    dueDateQuery.value = v.trim();
    applyFilters();
  }

  void updateEmployeeId(String v) {
    employeeIdQuery.value = v.trim();
    applyFilters();
  }

  void updateEmployeeName(String v) {
    employeeNameQuery.value = v.trim();
    applyFilters();
  }

  void updateDepartment(String v) {
    departmentQuery.value = v.trim();
    applyFilters();
  }

  void updateGroup(String v) {
    groupQuery.value = v.trim();
    applyFilters();
  }

  // Core filter logic combining ALL active criteria together (AND semantics)
  void applyFilters() {
    // Start from the full data set always (so filters are independent)
    final String statusFilter = selectedStatus.value;
    final String approverQ = approverCodeQuery.value.toLowerCase();
    final String empIdQ = employeeIdQuery.value.toLowerCase();
    final String empNameQ = employeeNameQuery.value.toLowerCase();
    final String deptQ = departmentQuery.value.toLowerCase();
    final String groupQ = groupQuery.value.toLowerCase();
    final String dueQ = dueDateQuery.value.toLowerCase();

    bool matchesStatus(ApprenticeContract item) {
      if (statusFilter.isEmpty || statusFilter == 'all') return true;
      if (statusFilter == 'Not Done')
        return item.inTStatusId != 9; // any not Done

      final id = item.inTStatusId;
      switch (statusFilter) {
        case 'New':
          return id == 1;
        case 'Per':
          return id == 2;
        case 'PTHC':
          return id == 3;
        case 'Leader':
          return id == 4;
        case 'Chief':
          return id == 5;
        case 'QLTC':
          return id == 6;
        case 'QLCC':
          return id == 7;
        case 'Director':
          return id == 8;
        case 'Done':
          return id == 9;
        default:
          return false;
      }
    }

    List<ApprenticeContract> result = [];
    for (final item in dataList) {
      if (!matchesStatus(item)) continue;
      if (approverQ.isNotEmpty &&
          !(item.vchRCodeApprover ?? '').toLowerCase().contains(approverQ))
        continue;
      if (empIdQ.isNotEmpty &&
          !(item.vchREmployeeId ?? '').toLowerCase().contains(empIdQ))
        continue;
      if (empNameQ.isNotEmpty &&
          !(item.vchREmployeeName ?? '').toLowerCase().contains(empNameQ))
        continue;
      if (deptQ.isNotEmpty &&
          !(item.vchRNameSection ?? '').toLowerCase().contains(deptQ))
        continue;
      if (groupQ.isNotEmpty &&
          !(item.chRCostCenterName ?? '').toLowerCase().contains(groupQ))
        continue;
      if (dueQ.isNotEmpty) {
        final dueDateStr = item.dtMDueDate != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item.dtMDueDate!))
            : '';
        if (!dueDateStr.toLowerCase().contains(dueQ)) continue;
      }
      result.add(item);
    }

    filterdataList.value = result;
    // Rebuild selection states to align with filtered list length
    selectRows.assignAll(List.generate(filterdataList.length, (_) => false));
  }

  // Old individual filter methods removed in favor of applyFilters().
  // Reset all filters
  void refreshFilteredList() {
    approverCodeQuery.value = '';
    employeeIdQuery.value = '';
    employeeNameQuery.value = '';
    departmentQuery.value = '';
    groupQuery.value = '';
    selectedStatus.value = '';
    filterdataList.assignAll(dataList);
    selectRows.assignAll(List.generate(filterdataList.length, (_) => false));
  }

  void refreshSearch() {
    approverCodeQuery.value = '';
    employeeIdQuery.value = '';
    employeeNameQuery.value = '';
    departmentQuery.value = '';
    groupQuery.value = '';
    selectedStatus.value = '';
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
                  false) ||
              (item.chRCostCenterName?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false) ||
              (item.chRPosition?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        ),
      );
    }
  }

  // lay du lieu data
  Future<void> fetchDummyData(String? section, String? chucVu) async {
    try {
      isLoading(true);
      http.Response response;
      switch (chucVu) {
        case "PTHC":
        case "Section Manager":
          // Lọc theo section thông qua search API
          // Có 2 trường hợp đầu vào:
          // 1) section = "2100: PR1-PR1" (chuỗi đơn) => value phải là ["2100: PR1-PR1"]
          // 2) section = '["2100: PR1-PR1", "1234: ABC-XYZ"]' (chuỗi JSON list) => parse ra List
          List<String> sectionValues;
          final trimmed = section == null ? "" : section.trim();
          if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
            try {
              final decoded = json.decode(trimmed);
              if (decoded is List) {
                sectionValues = decoded
                    .map((e) => e.toString().trim())
                    .toList();
              } else {
                sectionValues = [trimmed];
              }
            } catch (_) {
              sectionValues = [trimmed];
            }
          } else {
            sectionValues = [trimmed];
          }

          final filters = [
            {
              "field": "VCHR_CODE_SECTION",
              "value": sectionValues,
              "operator": "IN",
              "logicType": "AND",
            },
          ];
          final requestBody = {
            "pageNumber": -1,
            "pageSize": 10,
            "filters": filters,
          };
          // ignore: avoid_print
          print('fetchDummyData request: ${json.encode(requestBody)}');
          response = await http.post(
            Uri.parse(Common.API + Common.ApprenticeSreachBy),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          );
          break;
        case "Dept":
        case "Dept Manager":
          final filters = [
            {
              "field": "VCHR_CODE_SECTION",
              "value": "%$section%",
              "operator": "LIKE",
              "logicType": "AND",
            },
          ];
          final requestBody = {
            "pageNumber": -1,
            "pageSize": 10,
            "filters": filters,
          };
          // ignore: avoid_print
          print('fetchDummyData request: ${json.encode(requestBody)}');
          response = await http.post(
            Uri.parse(Common.API + Common.ApprenticeSreachBy),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          );
          break;
        case "Director":
        case "General Director":
          if (section == null || section.isEmpty) {
            throw Exception('Section is required for Director role');
          }
          List<String> sectionValues = section.split(",");
          final filters = [];
          for (var a in sectionValues) {
            filters.add({
              "field": "VCHR_CODE_SECTION",
              "value": '%${a.trim()}%',
              "operator": "LIKE",
              "logicType": "OR",
            });
          }
          final requestBody = {
            "pageNumber": -1,
            "pageSize": 10,
            "filters": filters,
          };
          // ignore: avoid_print
          print('fetchDummyData request: ${json.encode(requestBody)}');
          response = await http.post(
            Uri.parse(Common.API + Common.ApprenticeSreachBy),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          );
          break;
        default:
          // Lấy toàn bộ danh sách (không lọc theo section)
          response = await http.get(
            Uri.parse(Common.API + Common.ApprenticeGetAll),
            headers: {'Content-Type': 'application/json'},
          );
          break;
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // Một số API trả trực tiếp List, một số có dạng { data: { data: [...] }}
          final dynamic raw = jsonData['data'];
          List<dynamic> data;
          if (raw is Map && raw.containsKey('data')) {
            data = raw['data'] ?? [];
          } else if (raw is List) {
            data = raw;
          } else {
            data = [];
          }
          dataList.assignAll(
            data.map((e) => ApprenticeContract.fromJson(e)).toList(),
          );
          filterdataList.assignAll(dataList);
          selectRows.assignAll(List.generate(dataList.length, (_) => false));
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('Failed to load data (status ${response.statusCode})');
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
    String? chucVu,
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
          cloumn = "USER_APPROVER_DEFT";
          break;
        case "8":
          cloumn = "USER_APPROVER_DIRECTOR";
          break;
      }
      // Có 2 trường hợp đầu vào:
      // 1) section = "2100: PR1-PR1" (chuỗi đơn) => value phải là ["2100: PR1-PR1"]
      // 2) section = '["2100: PR1-PR1", "1234: ABC-XYZ"]' (chuỗi JSON list) => parse ra List
      List<String> sectionValues;
      final trimmed = section == null ? "" : section.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            sectionValues = decoded.map((e) => e.toString().trim()).toList();
          } else {
            sectionValues = [trimmed];
          }
        } catch (_) {
          sectionValues = [trimmed];
        }
      } else {
        sectionValues = [trimmed];
      }
      // Build request body (approval will only filter by status; adid applied locally)
      final List<Map<String, dynamic>> filters = [];
      if (statusId == 'approval') {
        filters.add({
          "field": "INT_STATUS_ID",
          "value": ["6", "7", "8"],
          "operator": "IN",
          "logicType": "AND",
        });
      } else if (statusId == 'PTHC') {
        filters.add({
          "field": "INT_STATUS_ID",
          "value": ["3", "4", "5"],
          "operator": "IN",
          "logicType": "AND",
        });
      } else if (statusId == 'Chief') {
        filters.add({
          "field": "INT_STATUS_ID",
          "value": ["4", "5"],
          "operator": "IN",
          "logicType": "AND",
        });
      } else {
        filters.add({
          "field": "INT_STATUS_ID",
          "value": statusId,
          "operator": "=",
          "logicType": "AND",
        });
      }

      if (section != null && section.isNotEmpty) {
        filters.add({
          "field": "VCHR_CODE_SECTION",
          "value": sectionValues,
          "operator": "IN",
          "logicType": "AND",
        });
      }

      if (adid != null &&
          adid.isNotEmpty &&
          statusId != 'PTHC' &&
          statusId != 'approval' &&
          statusId != 'Chief') {
        filters.add({
          "field": cloumn,
          "value": adid,
          "operator": "=",
          "logicType": "AND",
        });
      }

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
          if (statusId == 'PTHC') {
            dataList.assignAll(
              data
                  .where(
                    (a) =>
                        (a['vchR_LEADER_EVALUTION'] == adid &&
                            a['inT_STATUS_ID'] == 4) ||
                        (a['inT_STATUS_ID'] == 3) ||
                        (a['inT_STATUS_ID'] == 5 &&
                            a['useR_APPROVER_CHIEF'] == adid),
                  )
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
            // dữ liệu gốc
            originalList.assignAll(
              data
                  .where(
                    (a) =>
                        (a['vchR_LEADER_EVALUTION'] == adid &&
                            a['inT_STATUS_ID'] == 4) ||
                        (a['inT_STATUS_ID'] == 3) ||
                        (a['inT_STATUS_ID'] == 5 &&
                            a['useR_APPROVER_CHIEF'] == adid),
                  )
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
          } else if (statusId == 'approval' &&
              adid != null &&
              adid.isNotEmpty) {
            // Filter locally for matching approver ADID in any approval role
            final filtered = data.where((a) {
              return ((a['inT_STATUS_ID'] == 7 &&
                      a['useR_APPROVER_DEFT'] == adid) ||
                  (a['inT_STATUS_ID'] == 8 &&
                      a['useR_APPROVER_DIRECTOR'] == adid) ||
                  (a['inT_STATUS_ID'] == 6 &&
                      a['useR_APPROVER_SECTION_MANAGER'] == adid));
              // switch (chucVu) {
              //   case "Section Manager":
              //     return a['inT_STATUS_ID'] != null &&
              //         [6].contains(a['inT_STATUS_ID']) &&
              //         (a['userApproverSectionManager'] == adid ||
              //             a['useR_APPROVER_SECTION_MANAGER'] == adid);
              //   default:
              //     return ((a['inT_STATUS_ID'] == 7 &&
              //             a['useR_APPROVER_DEFT'] == adid) ||
              //         (a['inT_STATUS_ID'] == 8 &&
              //             a['useR_APPROVER_DIRECTOR'] == adid)
              //         ||(a['inT_STATUS_ID'] == 6 &&
              //             a['useR_APPROVER_SECTION_MANAGER'] == adid)
              //         );
              // }
            }).toList();
            dataList.assignAll(
              filtered
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
            originalList.assignAll(
              filtered
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
          } else if (statusId == 'Chief' && adid != null && adid.isNotEmpty) {
            // Filter locally for matching approver ADID in any approval role
            final filtered = data
                .where(
                  (a) =>
                      (a['useR_APPROVER_CHIEF'] == adid ||
                      a['vchR_LEADER_EVALUTION'] == adid),
                )
                .toList();
            dataList.assignAll(
              filtered
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
            originalList.assignAll(
              filtered
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
          } else {
            dataList.assignAll(
              data
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
            // dữ liệu gốc
            originalList.assignAll(
              data
                  .map((contract) => ApprenticeContract.fromJson(contract))
                  .toList(),
            );
          }
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
      final parsedEndDate = parseDateTime(contract.dtMEndDate);
      if (parsedEndDate != null &&
          parsedEndDate.difference(DateTime.now()).inDays.abs() <= 10) {
        throw Exception(tr('CheckTime'));
      }
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
        throw Exception('${error['message'] ?? response.body}');
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
      contract.vchRCodeSection = contract.vchRNameSection;
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

  // Send mail phản hồi từ chối đánh giá
  Future<void> sendEmailReturn(
    ApprenticeContract contract,
    String userApprover,
    String reason,
  ) async {
    try {
      //fetchPTHCData();
      List<dynamic> notApproval = [];
      // Add current contract to the list of not approved items
      final json = contract.toJson();
      final contractCopy = ApprenticeContract.fromJson(json);

      notApproval.add(contractCopy);
      contract.biTNoReEmployment = false;

      if (!reason.contains("Trả về từ báo cáo của nhân sự")) {
        if (contract.inTStatusId == 3) {
          contract.inTStatusId = 1;
        } else if (contract.inTStatusId == 4) {
          contract.inTStatusId = 3;
        } else if (contract.inTStatusId == 5) {
          contract.inTStatusId = 4;
        }
      }
      if (notApproval.isNotEmpty) {
        final specialSection = pthcList.firstWhere(
          (item) => item.section == "1120-1 : ADM-PER",
        );
        // Tối ưu lấy email cc và to, loại bỏ trùng lặp, kiểm tra null/empty một lần
        final sectionItems = pthcList.where(
          (item) => item.section == contract.vchRCodeSection,
        );
        final ccSet = <String>{};
        final toSet = <String>{};
        for (final item in sectionItems) {
          if (item.mailcc != null && item.mailcc!.trim().isNotEmpty) {
            ccSet.add(item.mailcc!.trim());
          }
          if (item.mailto != null && item.mailto!.trim().isNotEmpty) {
            toSet.add(item.mailto!.trim());
          }
        }
        if (specialSection.mailcc != null &&
            specialSection.mailcc!.trim().isNotEmpty) {
          ccSet.add(specialSection.mailcc!.trim());
        }
        if (specialSection.mailto != null &&
            specialSection.mailto!.trim().isNotEmpty) {
          toSet.add(specialSection.mailto!.trim());
        }
        final ccEmails = ccSet.join(';');
        final toEmails = toSet.join(';');
        final controlleruser = Get.put(DashboardControllerUser());
        controlleruser.SendMailCustom(
          '${specialSection.mailto};$toEmails',
          ccEmails,
          specialSection.mailbcc.toString(),
          notApproval,
          "Từ chối xác nhận",
          userApprover,
          reason,
        );
      }
    } catch (e) {
      throw Exception('$e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateKetQuaApprenticeContract(
    ApprenticeContract twocontract,
    String userUpdate,
    String ketquaOld,
  ) async {
    try {
      List<ApprenticeContract> listOld = [];
      listOld.add(twocontract);
      twocontract.vchRUserUpdate = userUpdate;
      twocontract.dtMUpdate = formatDateTime(DateTime.now());

      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdateApprentice}${twocontract.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract.toJson()),
      );
      if (response.statusCode == 200) {
        final controlleruser = Get.put(DashboardControllerUser());
        controlleruser.SendMailKetQua(
          "${twocontract.useRApproverSectionManager}@brothergroup.net",
          '$userUpdate@brothergroup.net',
          'khanhmf@brothergroup.net',
          listOld,
          ketquaOld,
          twocontract.vchRReasultsLeader.toString(),
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update contract: $e');
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
      //sau test delete
      // if (userApprover == "fujiokmi") {
      //   userApprover = 'vanug';
      // }
      final contract = getSelectedItems();
      if (contract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }

      // ⚡ PERFORMANCE OPTIMIZATION: Tạo Map để tìm kiếm O(1) thay vì O(n)
      // Tối ưu từ O(n²) xuống O(n) cho việc tìm kiếm originalList
      final Map<String, ApprenticeContract> originalMap = {};

      // Xây dựng Map với keys phù hợp để tìm kiếm nhanh
      for (final original in originalList) {
        // Ưu tiên theo ID nếu có
        if (original.id != null) {
          originalMap['id_${original.id}'] = original;
        }
        // Fallback theo Employee ID
        if (original.vchREmployeeId?.isNotEmpty == true) {
          originalMap['emp_${original.vchREmployeeId}'] = original;
        }
      }

      for (int i = 0; i < contract.length; i++) {
        // Nếu có nhập lý do (ít nhất 1 trong 3) thì kiểm tra xem có thay đổi gì so với dữ liệu gốc không
        if ((contract[i].nvchRApproverPer?.isNotEmpty ?? false)) {
          // 🚀 Tìm kiếm O(1) thay vì O(n) với indexWhere
          ApprenticeContract? original;

          // Tìm theo ID trước (ưu tiên)
          if (contract[i].id != null) {
            original = originalMap['id_${contract[i].id}'];
          }

          // Nếu không tìm thấy theo ID, tìm theo Employee ID
          if (original == null &&
              contract[i].vchREmployeeId?.isNotEmpty == true) {
            original = originalMap['emp_${contract[i].vchREmployeeId}'];
          }

          // Kiểm tra thay đổi nếu tìm thấy bản ghi gốc
          if (original != null) {
            final bool changed = original != contract[i];
            if (!changed) {
              // Không có thay đổi thực sự
              throw Exception('${tr('CapNhat')} ${contract[i].vchREmployeeId}');
            }
          }
        }
        contract[i].vchRUserUpdate = userUpdate;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        contract[i].inTStatusId = 2;
        contract[i].useRApproverPer = userApprover;
        contract[i].biTApproverPer = true;
        contract[i].nvchRApproverPer = '';
        contract[i].vchRCodeApprover =
            'HDHN${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
        contract[i].vchRLyThuyet = 'OK';
        contract[i].vchRThucHanh = 'OK';
        contract[i].vchRCompleteWork = 'OK';
        contract[i].vchRLearnWork = 'OK';
        contract[i].vchRThichNghi = 'OK';
        contract[i].vchRUseful = 'OK';
        contract[i].vchRContact = 'OK';
        contract[i].vcHNeedViolation = 'OK';
        contract[i].vchRReasultsLeader = 'OK';
        contract[i].biTNoReEmployment = true;
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListApprentice}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
        final controlleruser = Get.put(DashboardControllerUser());
        controlleruser.SendMail(
          '2',
          '$userApprover@brothergroup.net',
          '$userApprover@brothergroup.net',
          '$userApprover@brothergroup.net;khanhmf@brothergroup.net',
        );
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
    String chucVu,
    String caseUser,
  ) async {
    try {
      List<ApprenticeContract> contract = [];
      final contractOld = getSelectedItems();
      if (contractOld.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      // lấy dữ liệu gốc để thực hiện
      contract = contractOld
          .map((item) => ApprenticeContract.fromJson(item.toJson()))
          .toList();
      // So sánh những trường có ý nghĩa để xác định có thay đổi thực sự hay không
      // bool _hasMeaningfulChanges(
      //   ApprenticeContract original,
      //   ApprenticeContract edited,
      // ) {
      //   bool diffStr(String? a, String? b) => (a ?? '') != (b ?? '');
      //   bool diffBool(bool? a, bool? b) => (a ?? false) != (b ?? false);
      //   return
      //   // Điểm đánh giá/Leader
      //   diffStr(original.vchRLyThuyet, edited.vchRLyThuyet) ||
      //       diffStr(original.vchRThucHanh, edited.vchRThucHanh) ||
      //       diffStr(original.vchRCompleteWork, edited.vchRCompleteWork) ||
      //       diffStr(original.vchRLearnWork, edited.vchRLearnWork) ||
      //       diffStr(original.vchRThichNghi, edited.vchRThichNghi) ||
      //       diffStr(original.vchRUseful, edited.vchRUseful) ||
      //       diffStr(original.vchRContact, edited.vchRContact) ||
      //       diffStr(original.vcHNeedViolation, edited.vcHNeedViolation) ||
      //       diffStr(original.vchRReasultsLeader, edited.vchRReasultsLeader) ||
      //       // Tái tuyển dụng và lý do
      //       diffBool(original.biTNoReEmployment, edited.biTNoReEmployment) ||
      //       diffStr(original.nvchRNoReEmpoyment, edited.nvchRNoReEmpoyment) ||
      //       // Ghi chú
      //       diffStr(original.vchRNote, edited.vchRNote);
      // }

      // ⚡ PERFORMANCE OPTIMIZATION: Tạo Map để tìm kiếm O(1) thay vì O(n)
      // Tối ưu từ O(n²) xuống O(n) cho việc tìm kiếm originalList
      final Map<String, ApprenticeContract> originalMap = {};

      // Xây dựng Map với keys phù hợp để tìm kiếm nhanh
      for (final original in originalList) {
        // Ưu tiên theo ID nếu có
        if (original.id != null) {
          originalMap['id_${original.id}'] = original;
        }
        // Fallback theo Employee ID
        if (original.vchREmployeeId?.isNotEmpty == true) {
          originalMap['emp_${original.vchREmployeeId}'] = original;
        }
      }

      for (int i = 0; i < contract.length; i++) {
        if ((contract[i].nvchrApproverDeft?.isNotEmpty ?? false) ||
            (contract[i].nvchRApproverManager?.isNotEmpty ?? false)) {
          // 🚀 Tìm kiếm O(1) thay vì O(n) với indexWhere
          ApprenticeContract? original;

          // Tìm theo ID trước (ưu tiên)
          if (contract[i].id != null) {
            original = originalMap['id_${contract[i].id}'];
          }

          // Nếu không tìm thấy theo ID, tìm theo Employee ID
          if (original == null &&
              contract[i].vchREmployeeId?.isNotEmpty == true) {
            original = originalMap['emp_${contract[i].vchREmployeeId}'];
          }

          // Kiểm tra thay đổi nếu tìm thấy bản ghi gốc
          if (original != null) {
            // final bool hasChanges = _hasMeaningfulChanges(
            //   original,
            //   contract[i],
            // );
            // if (!hasChanges && contract[i].inTStatusId == 4) {
            //   // Không có thay đổi thực sự
            //   throw Exception('${tr('CapNhat')} ${contract[i].vchREmployeeId}');
            // }
          }
        }
        contract[i].vchRUserUpdate = userUpdate;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        // cập nhật lại các lý do từ chối
        contract[i].nvchRApproverManager = '';
        contract[i].nvchrApproverDeft = '';
        contract[i].biTApproverSectionManager = true;
        contract[i].bitApproverDeft = true;
        switch (contract[i].inTStatusId) {
          case 3:
            contract[i].inTStatusId = 4;
            contract[i].nvchRPthcSection = userUpdate;
            contract[i].vchRLeaderEvalution = userApprover;
            contract[i].biTNoReEmployment = true;
            contract[i].biTApproverChief = true;
            contract[i].nvchRApproverChief = '';
            break;
          case 4:
            if (contract[i].vchRReasultsLeader == 'NG' &&
                (contract[i].vchRLyThuyet == 'OK' &&
                    contract[i].vchRThucHanh == 'OK' &&
                    contract[i].vchRCompleteWork == 'OK' &&
                    contract[i].vchRLearnWork == 'OK' &&
                    contract[i].vchRThichNghi == 'OK' &&
                    contract[i].vchRUseful == 'OK' &&
                    contract[i].vchRContact == 'OK' &&
                    contract[i].vcHNeedViolation == 'OK')) {
              throw Exception(
                '${tr('InputError2')} ${contract[i].vchREmployeeId}',
              );
            }
            if (contract[i].vchRReasultsLeader != 'NG' &&
                (contract[i].vchRLyThuyet != 'OK' ||
                    contract[i].vchRThucHanh != 'OK' ||
                    contract[i].vchRCompleteWork != 'OK' ||
                    contract[i].vchRLearnWork != 'OK' ||
                    contract[i].vchRThichNghi != 'OK' ||
                    contract[i].vchRUseful != 'OK' ||
                    contract[i].vchRContact != 'OK' ||
                    contract[i].vcHNeedViolation != 'OK')) {
              throw Exception(
                '${tr('InputError3')} ${contract[i].vchREmployeeId}',
              );
            }
            // &&(contract[i].vchRNote == '' ||
            //       contract[i].vchRNote == null)
            if (contract[i].biTNoReEmployment == false &&
                (contract[i].nvchRNoReEmpoyment == null ||
                    contract[i].nvchRNoReEmpoyment == "")) {
              throw Exception(
                '${tr('InputError')} ${contract[i].vchREmployeeId}',
              );
            }
            if (chucVu == "Chief" || chucVu == "Expert") {
              contract[i].inTStatusId = 6;
              contract[i].vchRLeaderEvalution = userUpdate;
              contract[i].useRApproverChief = userUpdate;
              contract[i].dtMLeadaerEvalution = formatDateTime(DateTime.now());
              contract[i].dtMApproverChief = formatDateTime(DateTime.now());
              contract[i].biTApproverChief = true;
              contract[i].nvchRApproverChief = '';
              contract[i].useRApproverSectionManager = userApprover;
              contract[i].biTApproverSectionManager = true;
            } else if (chucVu == "Section Manager") {
              contract[i].inTStatusId = 7;
              contract[i].vchRLeaderEvalution = userUpdate;
              contract[i].useRApproverChief = userUpdate;
              contract[i].useRApproverSectionManager = userUpdate;
              contract[i].dtMApproverManager = formatDateTime(DateTime.now());
              contract[i].dtMLeadaerEvalution = formatDateTime(DateTime.now());
              contract[i].dtMApproverChief = formatDateTime(DateTime.now());
              contract[i].biTApproverChief = false;
              contract[i].nvchRApproverChief = '';
              contract[i].biTApproverSectionManager = true;
              contract[i].nvchRApproverManager = '';
              contract[i].userApproverDeft = userApprover;
              contract[i].bitApproverDeft = true;
            } else {
              contract[i].inTStatusId = 5;
              contract[i].vchRLeaderEvalution = userUpdate;
              contract[i].useRApproverChief = userApprover;
              contract[i].dtMLeadaerEvalution = formatDateTime(DateTime.now());
              contract[i].biTApproverChief = true;
              contract[i].nvchRApproverChief = '';
            }
            break;
          case 5:
            if (contract[i].biTApproverChief != true &&
                (contract[i].nvchRApproverChief == null ||
                    contract[i].nvchRApproverChief == "")) {
              throw Exception(
                '${tr('TuChoiPheDuyet')} ${contract[i].vchREmployeeId}',
              );
            }
            if (contract[i].biTApproverChief == false &&
                contract[i].nvchRApproverChief != "") {
              contract[i].inTStatusId = 4;
              contract[i].useRApproverChief = userUpdate;
              contract[i].dtMApproverChief = formatDateTime(DateTime.now());
            } else {
              switch (caseUser) {
                case "ACC":
                  contract[i].inTStatusId = 7;
                  contract[i].useRApproverChief = userUpdate;
                  contract[i].useRApproverSectionManager = userApprover;
                  contract[i].dtMApproverChief = formatDateTime(DateTime.now());
                  contract[i].biTApproverSectionManager = true;
                  contract[i].dtMApproverManager = formatDateTime(
                    DateTime.now(),
                  );
                  contract[i].nvchRApproverManager = '';
                  contract[i].userApproverDeft = userApprover;
                  contract[i].bitApproverDeft = true;
                  break;
                default:
                  if (chucVu == "Section Manager") {
                    contract[i].inTStatusId = 7;
                    contract[i].vchRLeaderEvalution = userUpdate;
                    contract[i].useRApproverChief = userUpdate;
                    contract[i].useRApproverSectionManager = userUpdate;
                    contract[i].dtMApproverManager = formatDateTime(
                      DateTime.now(),
                    );
                    contract[i].dtMLeadaerEvalution = formatDateTime(
                      DateTime.now(),
                    );
                    contract[i].dtMApproverChief = formatDateTime(
                      DateTime.now(),
                    );
                    contract[i].biTApproverChief = false;
                    contract[i].nvchRApproverChief = '';
                    contract[i].biTApproverSectionManager = true;
                    contract[i].nvchRApproverManager = '';
                    contract[i].userApproverDeft = userApprover;
                    contract[i].bitApproverDeft = true;
                  } else {
                    contract[i].inTStatusId = 6;
                    contract[i].useRApproverChief = userUpdate;
                    contract[i].useRApproverSectionManager = userApprover;
                    contract[i].dtMApproverChief = formatDateTime(
                      DateTime.now(),
                    );
                  }
                  break;
              }
            }
            break;
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
        // điều kiện
        if (chucVu == "PTHC") {
          final controlleruser = Get.put(DashboardControllerUser());
          controlleruser.SendMail(
            '2',
            '$userApprover@brothergroup.net',
            '$userApprover@brothergroup.net',
            '$userApprover@brothergroup.net;khanhmf@brothergroup.net',
          );
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // update thời gian tới hạn
  Future<void> updateDTM_END(
    ApprenticeContract contract,
    String userUpdate,
  ) async {
    try {
      contract.vchRUserUpdate = userUpdate;
      contract.dtMUpdate = formatDateTime(DateTime.now());

      //contract.

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

  /// Lay thông tin gửi mail
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
          pthcList.assignAll(
            data.map((user) => PthcGroup.fromJson(user)).toList(),
          );
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('Failed to load dats');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }

  // update thong tin phe duyet
  Future<void> updateListApprenticeContractApproval(
    String userApprover, {
    String? nextApproverAdid,
  }) async {
    try {
      final contractOld = getSelectedItems();
      //fetchPTHCData();
      List<dynamic> notApproval = [];
      List<ApprenticeContract> contract = [];
      String mailSend = "";
      String sectionAp = "";
      String PheDuyetMail = "";
      if (contractOld.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      // lấy dữ liệu gốc để thực hiện
      contract = contractOld
          .map((item) => ApprenticeContract.fromJson(item.toJson()))
          .toList();
      for (int i = 0; i < contract.length; i++) {
        contract[i].vchRUserUpdate = userApprover;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        // Tìm vị trí bắt đầu của phần dept
        List<String> parts = (contract[i].vchRCodeSection ?? "").split(": ");
        String prPart = parts[1];

        // Tách phần phòng ban
        List<String> prParts = prPart.split("-");
        String dept = prParts[0];

        // lay thong tin phong
        sectionAp = contract[i].vchRCodeSection.toString();
        switch (contract[i].inTStatusId) {
          case 6:
            contract[i].dtMApproverManager = formatDateTime(DateTime.now());
            contract[i].useRApproverSectionManager = userApprover;
            if (contract[i].biTApproverSectionManager != false) {
              contract[i].inTStatusId = 7;
              contract[i].bitApproverDeft = true;
              // Use selected next approver if provided, otherwise fallback to API lookup
              if (nextApproverAdid != null && nextApproverAdid.isNotEmpty) {
                mailSend = nextApproverAdid;
              } else {
                mailSend = await NextApprovel(
                  section: "",
                  chucVu: "Dept Manager",
                  dept: dept,
                );
              }
              contract[i].userApproverDeft = mailSend.split('@')[0];
            } else {
              if ((contract[i].nvchRApproverManager?.isEmpty ?? true)) {
                throw Exception(
                  '${tr('NotApproval')} ${contract[i].vchREmployeeName}',
                );
              }
              final json = contract[i].toJson();
              final contractCopy = ApprenticeContract.fromJson(json);
              notApproval.add(contractCopy);
              contract[i].inTStatusId = 4;
            }
            break;
          case 7:
            //xu ly khi xong
            contract[i].dtmApproverDeft = formatDateTime(DateTime.now());
            contract[i].userApproverDeft = userApprover;
            if (contract[i].bitApproverDeft != false) {
              contract[i].inTStatusId = 9;
            } else {
              if ((contract[i].nvchrApproverDeft?.isEmpty ?? true)) {
                throw Exception(
                  '${tr('NotApproval')} ${contract[i].vchREmployeeName}',
                );
              }
              final json = contract[i].toJson();
              final contractCopy = ApprenticeContract.fromJson(json);
              notApproval.add(contractCopy);
              contract[i].inTStatusId = 4;
              // Thêm email của quản lý phòng ban vào danh sách phê duyệt
              final chief = contract[i].useRApproverChief;
              if (chief != null && chief.isNotEmpty) {
                final email = '$chief@brothergroup.net';
                final existing = PheDuyetMail.split(';')
                    .where((e) => e.trim().isNotEmpty)
                    .map((e) => e.toLowerCase())
                    .toList();
                if (!existing.contains(email.toLowerCase())) {
                  PheDuyetMail += '$email;';
                }
              }
            }
            break;
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
        //mail phe duyet
        if (mailSend != '') {
          //controlleruser.SendMail('5', mailSend, mailSend, mailSend);

          // controlleruser.SendMail(
          //   '5',
          //   "vietdo@brothergroup.net,vanug@brothergroup.net,tuanho@brothergroup.net,huyenvg@brothergroup.net, hoaiph@brothergroup.net",
          //   "nguyenduy.khanh@brother-bivn.com.vn;hoangviet.dung@brother-bivn.com.vn",
          //   "vuduc.hai@brother-bivn.com.vn",
          // );
        }
        // mail canh bao
        //Special case for section
        if (notApproval.isNotEmpty) {
          final specialSection = pthcList.firstWhere(
            (item) => item.section == "1120-1 : ADM-PER",
          );
          // Tối ưu lấy email cc và to, loại bỏ trùng lặp, kiểm tra null/empty một lần
          final sectionItems = pthcList.where(
            (item) => item.section == sectionAp,
          );
          final ccSet = <String>{};
          final toSet = <String>{};
          for (final item in sectionItems) {
            if (item.mailcc != null && item.mailcc!.trim().isNotEmpty) {
              ccSet.add(item.mailcc!.trim());
            }
            if (item.mailto != null && item.mailto!.trim().isNotEmpty) {
              toSet.add(item.mailto!.trim());
            }
          }
          if (specialSection.mailcc != null &&
              specialSection.mailcc!.trim().isNotEmpty) {
            ccSet.add(specialSection.mailcc!.trim());
          }
          if (specialSection.mailto != null &&
              specialSection.mailto!.trim().isNotEmpty) {
            toSet.add(specialSection.mailto!.trim());
          }
          final ccEmails = ccSet.join(';');
          final toEmails = toSet.join(';');
          final controlleruser = Get.put(DashboardControllerUser());
          controlleruser.SendMailCustom(
            toEmails,
            ccEmails.isNotEmpty && PheDuyetMail.isNotEmpty
                ? '$ccEmails;$PheDuyetMail'
                : ccEmails + PheDuyetMail,
            specialSection.mailbcc.toString(),
            notApproval,
            "Từ chối phê duyệt",
            userApprover,
            null,
          );
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('$e');
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

  // delete list
  Future<void> deleteListApprenticeContract() async {
    try {
      isLoading(true);
      final contract = getSelectedItems();

      if (contract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }

      // Lấy danh sách ID từ các item được chọn
      final ids = contract.map((contract) => contract.id).toList();

      final endpoint = Common.DeleteApprenticeMultiID;
      final response = await http.delete(
        // Thường xóa nhiều item dùng POST hoặc DELETE với body
        Uri.parse('${Common.API}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ids), // Gửi danh sách ID dưới dạng JSON
      );

      if (response.statusCode == 200) {
        // Xóa thành công, cập nhật UI
        //await fetchDataBy();
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
          //..vchRCodeSection = row[4]?.value?.toString()
          ..vchRCodeSection = row[4]?.value?.toString().replaceAll(
            RegExp(r'\s*:\s*'),
            ' : ',
          )
          ..vchRNameSection = row[4]?.value?.toString().replaceAll(
            RegExp(r'\s*:\s*'),
            ' : ',
          )
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
          ..dtMEndDate = formatDateTime(row[12]?.value?.toString())
          ..fLGoLeaveLate = row[13]?.value != null
              ? double.tryParse(row[13]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLNotLeaveDay = row[14]?.value != null
              ? double.tryParse(row[14]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..inTViolation = row[15]?.value != null
              ? int.tryParse(row[15]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation
          ..vchRLyThuyet //= row[14]!.value.toString()
          ..vchRThucHanh // = row[15]!.value.toString()
          ..vchRCompleteWork //= row[16]!.value.toString()
          ..vchRLearnWork //= row[17]!.value.toString()
          ..vchRThichNghi //= row[18]!.value.toString()
          ..vchRUseful //= row[19]!.value.toString()
          ..vchRContact //= row[20]!.value.toString()
          ..vcHNeedViolation //= row[21]!.value.toString()
          ..vchRReasultsLeader //= row[22]!.value.toString()
          ..biTNoReEmployment = true
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
          ..vchRNote //= row[23]!.value.toString()
          ..useRApproverPer
          ..useRApproverChief
          ..useRApproverSectionManager
          ..useRApproverDirector
          ..dtmApproverDeft
          ..userApproverDeft
          ..bitApproverDeft
          ..nvchrApproverDeft;
        // Validate required fields
        if (twocontract.vchREmployeeId?.isEmpty == true ||
            twocontract.vchREmployeeName?.isEmpty == true ||
            twocontract.vchRCodeSection?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }
        if (!await checkEmployeeExists(twocontract.vchREmployeeId!)) {
          _i++;
          continue; // Skip invalid rows
        }
        final parsedEndDate = parseDateTime(twocontract.dtMEndDate);
        if (parsedEndDate != null &&
            parsedEndDate.difference(DateTime.now()).inDays.abs() <= 10) {
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
          ..vchRCodeSection = row[4]?.value?.toString().replaceAll(
            RegExp(r'\s*:\s*'),
            ' : ',
          )
          ..vchRNameSection = row[4]?.value?.toString().replaceAll(
            RegExp(r'\s*:\s*'),
            ' : ',
          )
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
          ..dtMEndDate = formatDateTime(row[12]?.value?.toString())
          ..fLGoLeaveLate = row[13]?.value != null
              ? double.tryParse(row[13]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLNotLeaveDay = row[14]?.value != null
              ? double.tryParse(row[14]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..inTViolation = row[15]?.value != null
              ? int.tryParse(row[15]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation
          ..vchRLyThuyet
          ..vchRThucHanh
          ..vchRCompleteWork
          ..vchRLearnWork
          ..vchRThichNghi
          ..vchRUseful
          ..vchRContact
          ..vcHNeedViolation
          ..vchRReasultsLeader
          ..biTNoReEmployment = true
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
          ..useRApproverDirector
          ..dtmApproverDeft
          ..userApproverDeft
          ..bitApproverDeft
          ..nvchrApproverDeft;
        // Validate required fields
        if (twocontract.vchREmployeeId?.isEmpty == true ||
            twocontract.vchREmployeeName?.isEmpty == true ||
            twocontract.vchRCodeSection?.isEmpty == true) {
          _i++;
          continue; // Skip invalid rows
        }
        if (!await checkEmployeeExists(twocontract.vchREmployeeId!)) {
          _i++;
          continue; // Skip invalid rows
        }
        final parsedEndDate = parseDateTime(twocontract.dtMEndDate);
        if (parsedEndDate != null &&
            parsedEndDate.difference(DateTime.now()).inDays.abs() <= 10) {
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

  // ham nhap thong tin tu file
  Future<void> importExceltoApp(Uint8List bytes, String userUpdate) async {
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

      // 4. Refresh data & tracking errors
      final List<ApprenticeContract> importedTwoContract = [];
      final List<Map<String, dynamic>> errorRows = []; // store raw + reason
      lastImportErrors.clear();
      lastImportErrorExcel.value = null;
      int _i = 19;

      // Start from row 1 (skip header row) and process until empty row
      while (_i < rows.length &&
          rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];

        // Lấy thông tin employeeId để tìm dữ liệu hiện có
        final employeeId = row[1]?.value?.toString();

        if (employeeId == null || employeeId.isEmpty) {
          errorRows.add({
            'row': _i + 1,
            'employeeId': employeeId ?? '',
            'reason': 'Thiếu mã nhân viên',
          });
          lastImportErrors.add('Row ${_i + 1}: Thiếu mã nhân viên');
          _i++;
          continue;
        }

        // Tìm dữ liệu hiện có từ filterdataList và dataList
        final existingDataFromFilter = filterdataList.firstWhere(
          (item) => item.vchREmployeeId == employeeId,
          orElse: () => ApprenticeContract(),
        );

        final existingDataFromData = dataList.firstWhere(
          (item) => item.vchREmployeeId == employeeId,
          orElse: () => ApprenticeContract(),
        );

        // Ưu tiên dữ liệu từ filterdataList, nếu không có thì dùng từ dataList
        final existingData = existingDataFromFilter.id != 0
            ? existingDataFromFilter
            : existingDataFromData;

        // Create and populate - giữ nguyên các trường khác từ dữ liệu hiện có
        final twocontract = ApprenticeContract()
          ..id = existingData.id ?? 0
          ..vchRCodeApprover = existingData.vchRCodeApprover
          ..vchRCodeSection = existingData.vchRCodeSection
          ..vchRNameSection = existingData.vchRNameSection
          ..vchREmployeeId = employeeId
          ..vchRTyperId = existingData.vchRTyperId
          ..vchREmployeeName = existingData.vchREmployeeName
          ..dtMBrithday = existingData.dtMBrithday
          ..chRPosition = existingData.chRPosition
          ..chRCodeGrade = existingData.chRCodeGrade
          ..chRCostCenterName = existingData.chRCostCenterName
          ..dtMJoinDate = existingData.dtMJoinDate
          ..dtMEndDate = existingData.dtMEndDate
          ..fLGoLeaveLate = existingData.fLGoLeaveLate
          ..fLNotLeaveDay = existingData.fLNotLeaveDay
          ..inTViolation = existingData.inTViolation
          // CẬP NHẬT các trường từ file Excel
          ..nvarchaRViolation = row[16]?.value
              ?.toString() // Cập nhật từ file
          ..vchRLyThuyet = row[17]?.value
              ?.toString() // Cập nhật từ file
          ..vchRThucHanh = row[18]?.value
              ?.toString() // Cập nhật từ file
          ..vchRCompleteWork = row[19]?.value
              ?.toString() // Cập nhật từ file
          ..vchRLearnWork = row[20]?.value
              ?.toString() // Cập nhật từ file
          ..vchRThichNghi = row[21]?.value
              ?.toString() // Cập nhật từ file
          ..vchRUseful = row[22]?.value
              ?.toString() // Cập nhật từ file
          ..vchRContact = row[23]?.value
              ?.toString() // Cập nhật từ file
          ..vcHNeedViolation = row[24]?.value
              ?.toString() // Cập nhật từ file
          ..vchRReasultsLeader = row[25]?.value
              ?.toString() // Cập nhật từ file
          ..biTNoReEmployment = row[26]?.value != null
              ? (row[26]!.value.toString().toLowerCase() == 'true' ||
                    row[26]!.value.toString() == '1')
              : existingData.biTNoReEmployment
          // Giữ nguyên các trường khác từ dữ liệu hiện có
          ..nvchRNoReEmpoyment = existingData.nvchRNoReEmpoyment
          ..nvchRPthcSection = existingData.nvchRPthcSection
          ..vchRLeaderEvalution = existingData.vchRLeaderEvalution
          ..dtMLeadaerEvalution = existingData.dtMLeadaerEvalution
          ..biTApproverPer = existingData.biTApproverPer
          ..nvchRApproverPer = existingData.nvchRApproverPer
          ..dtMApproverPer = existingData.dtMApproverPer
          ..nvchRApproverChief = existingData.nvchRApproverChief
          ..dtMApproverChief = existingData.dtMApproverChief
          ..biTApproverSectionManager = existingData.biTApproverSectionManager
          ..nvchRApproverManager = existingData.nvchRApproverManager
          ..dtMApproverManager = existingData.dtMApproverManager
          ..biTApproverDirector = existingData.biTApproverDirector
          ..nvchRApproverDirector = existingData.nvchRApproverDirector
          ..dtMApproverDirector = existingData.dtMApproverDirector
          ..vchRUserCreate = existingData.vchRUserCreate ?? userUpdate
          ..dtMCreate = existingData.dtMCreate ?? formatDateTime(DateTime.now())
          ..vchRUserUpdate = userUpdate
          ..dtMUpdate = formatDateTime(DateTime.now())
          ..inTStatusId = existingData.inTStatusId ?? 1
          ..vchRNote = existingData.vchRNote
          ..useRApproverPer = existingData.useRApproverPer
          ..useRApproverChief = existingData.useRApproverChief
          ..useRApproverSectionManager = existingData.useRApproverSectionManager
          ..useRApproverDirector = existingData.useRApproverDirector
          ..dtmApproverDeft = existingData.dtmApproverDeft
          ..userApproverDeft = existingData.userApproverDeft
          ..bitApproverDeft = existingData.bitApproverDeft
          ..nvchrApproverDeft = existingData.nvchrApproverDeft;

        // Validate required fields
        if (twocontract.vchREmployeeId?.isEmpty == true ||
            twocontract.vchREmployeeName?.isEmpty == true ||
            twocontract.vchRCodeSection?.isEmpty == true) {
          errorRows.add({
            'row': _i + 1,
            'employeeId': employeeId,
            'reason': 'Thiếu thông tin bắt buộc',
          });
          lastImportErrors.add('Row ${_i + 1}: Thiếu thông tin bắt buộc');
          _i++;
          continue;
        }

        if (!await checkEmployeeExists(twocontract.vchREmployeeId!)) {
          errorRows.add({
            'row': _i + 1,
            'employeeId': employeeId,
            'reason': 'Nhân viên không tồn tại',
          });
          lastImportErrors.add('Row ${_i + 1}: Nhân viên không tồn tại');
          _i++;
          continue;
        }

        final parsedEndDate = parseDateTime(twocontract.dtMEndDate);
        if (parsedEndDate != null &&
            parsedEndDate.difference(DateTime.now()).inDays.abs() <= 10) {
          errorRows.add({
            'row': _i + 1,
            'employeeId': employeeId,
            'reason': 'Hạn đánh giá quá gần (<=10 ngày)',
          });
          lastImportErrors.add(
            'Row ${_i + 1}: Hạn đánh giá quá gần (<=10 ngày)',
          );
          _i++;
          continue;
        }

        importedTwoContract.add(twocontract);
        _i++;
      }

      // 5. kiem tra so luong du lieu import
      if (importedTwoContract.isEmpty) {
        // Tạo file lỗi nếu có errorRows
        if (errorRows.isNotEmpty) {
          final errorExcel = Excel.createExcel();
          final Sheet sheetErrors = errorExcel['Errors'];
          sheetErrors.appendRow([
            TextCellValue('Row'),
            TextCellValue('EmployeeId'),
            TextCellValue('Reason'),
          ]);
          for (final er in errorRows) {
            sheetErrors.appendRow([
              TextCellValue(er['row'].toString()),
              TextCellValue(er['employeeId']?.toString() ?? ''),
              TextCellValue(er['reason']?.toString() ?? ''),
            ]);
          }
          final bytesErr = errorExcel.encode();
          if (bytesErr != null) {
            lastImportErrorExcel.value = Uint8List.fromList(bytesErr);
          }
        }
        throw Exception('Không có dữ liệu hợp lệ để import');
      } else if (errorRows.isNotEmpty) {
        // Có cả dữ liệu đúng lẫn lỗi: tạo file lỗi để người dùng xem
        final errorExcel = Excel.createExcel();
        final Sheet sheetErrors = errorExcel['Errors'];
        sheetErrors.appendRow([
          TextCellValue('Row'),
          TextCellValue('EmployeeId'),
          TextCellValue('Reason'),
        ]);
        for (final er in errorRows) {
          sheetErrors.appendRow([
            TextCellValue(er['row'].toString()),
            TextCellValue(er['employeeId']?.toString() ?? ''),
            TextCellValue(er['reason']?.toString() ?? ''),
          ]);
        }
        final bytesErr = errorExcel.encode();
        if (bytesErr != null) {
          lastImportErrorExcel.value = Uint8List.fromList(bytesErr);
        }
      }
    } catch (e) {
      throw Exception('Import failed: $e');
    } finally {
      isLoading(false);
    }
  }

  // ham format String to date
  DateTime? parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    final formats = [
      'yyyy-MM-dd HH:mm:ss.SSS',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd',
    ];
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateString.replaceAll(' ', ''));
      } catch (e) {
        continue;
      }
    }
    return null;
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

  // check dữ liệu nhân viên
  Future<bool> checkEmployeeExists(String employeeId) async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse('${Common.API}${Common.GetEmployeeByStaffID}$employeeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData['data'] != null;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      isLoading(false);
    }
  }

  // cac thuoc tinh update
  void updateVchrLythuyet(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRThucHanh == 'OK' &&
        item.vchRThichNghi == 'OK' &&
        item.vchRCompleteWork == 'OK' &&
        item.vchRLearnWork == 'OK' &&
        item.vchRContact == 'OK' &&
        item.vcHNeedViolation == 'OK' &&
        item.vchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vchRLyThuyet = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateThucHanh(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRLyThuyet == 'OK' &&
        item.vchRThichNghi == 'OK' &&
        item.vchRCompleteWork == 'OK' &&
        item.vchRLearnWork == 'OK' &&
        item.vchRContact == 'OK' &&
        item.vcHNeedViolation == 'OK' &&
        item.vchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vchRThucHanh = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateCompleteWork(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRLyThuyet == 'OK' &&
        item.vchRThichNghi == 'OK' &&
        item.vchRThucHanh == 'OK' &&
        item.vchRLearnWork == 'OK' &&
        item.vchRContact == 'OK' &&
        item.vcHNeedViolation == 'OK' &&
        item.vchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vchRCompleteWork = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateStudyWork(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRLyThuyet == 'OK' &&
        item.vchRThichNghi == 'OK' &&
        item.vchRCompleteWork == 'OK' &&
        item.vchRThucHanh == 'OK' &&
        item.vchRContact == 'OK' &&
        item.vcHNeedViolation == 'OK' &&
        item.vchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vchRLearnWork = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateThichNghi(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRLyThuyet == 'OK' &&
        item.vchRThucHanh == 'OK' &&
        item.vchRCompleteWork == 'OK' &&
        item.vchRLearnWork == 'OK' &&
        item.vchRContact == 'OK' &&
        item.vcHNeedViolation == 'OK' &&
        item.vchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vchRThichNghi = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateUseful(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRLyThuyet == 'OK' &&
        item.vchRThichNghi == 'OK' &&
        item.vchRCompleteWork == 'OK' &&
        item.vchRLearnWork == 'OK' &&
        item.vchRContact == 'OK' &&
        item.vcHNeedViolation == 'OK' &&
        item.vchRThucHanh == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vchRUseful = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateContact(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRLyThuyet == 'OK' &&
        item.vchRThichNghi == 'OK' &&
        item.vchRCompleteWork == 'OK' &&
        item.vchRLearnWork == 'OK' &&
        item.vchRThucHanh == 'OK' &&
        item.vcHNeedViolation == 'OK' &&
        item.vchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vchRContact = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateNoiQuy(String employeeCode, String diem) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!diem.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.vchRLyThuyet == 'OK' &&
        item.vchRThichNghi == 'OK' &&
        item.vchRCompleteWork == 'OK' &&
        item.vchRLearnWork == 'OK' &&
        item.vchRContact == 'OK' &&
        item.vchRThucHanh == 'OK' &&
        item.vchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.vcHNeedViolation = diem;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateCuoicung(String employeeCode, String reason) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    item.vchRReasultsLeader = reason;
    if (reason == 'OK') {
      item.vchRNote = '';
    }
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateRehireStatus(String employeeCode, bool value) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    item.biTNoReEmployment = value;
    if (value == true) {
      item.nvchRNoReEmpoyment = "";
    }
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateNotRehireReason(String employeeCode, String reason) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    item.nvchRNoReEmpoyment = reason;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateNote(String employeeCode, String reason) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].vchRNote = reason;
      filterdataList[index].vchRNote = reason;
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  // update thong tin phe duyet
  void updateNotRehireReasonApprovel(
    String employeeCode,
    String reason,
    int? statusId,
  ) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    switch (statusId) {
      case 5:
        item.nvchRApproverChief = reason;
        break;
      case 6:
        item.nvchRApproverManager = reason;
        break;
      case 7:
        item.nvchrApproverDeft = reason;
        break;
      default:
        break;
    }
    //dataList.refresh();
    filterdataList.refresh();
  }

  void updateRehireStatusApprovel(
    String employeeCode,
    bool value,
    int? statusId,
  ) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    switch (statusId) {
      case 5:
        item.biTApproverChief = value;
        break;
      case 6:
        item.biTApproverSectionManager = value;
        break;
      case 7:
        item.bitApproverDeft = value;
        break;
      default:
        break;
    }
    dataList.refresh();
    filterdataList.refresh();
  }

  // lấy mail trưởng phòng, giám đốc, quản lý
  Future<String> NextApprovel({
    String? section,
    String? chucVu,
    String? dept,
  }) async {
    try {
      isLoading(true);

      // Build URI with optional parameters
      final uri = Uri.parse('${Common.API}${Common.UserApprover}').replace(
        queryParameters: {
          if (section != null) 'section': section,
          if (chucVu != null) 'positionGroups': chucVu,
          if (dept != null) 'dept': dept,
        },
      );

      // Make HTTP request
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      // Handle response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // Process and join emails in one efficient operation
          final adidList = (jsonData['data'] as List)
              .map((item) => ApproverUser.fromJson(item))
              .map((user) => user.chREmployeeAdid ?? "")
              .where((adid) => adid.isNotEmpty)
              .toList();
          return adidList.isNotEmpty ? adidList.first : "";
        }
        throw Exception(
          'API request failed: ${jsonData['message'] ?? 'Unknown error'}',
        );
      }
      throw Exception(
        'HTTP request failed with status: ${response.statusCode}',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch approvers: ${e.toString()}');
      return "";
    } finally {
      isLoading(false);
    }
  }

  // lay thong tin section
  Future<void> fetchSectionList(String? section, String? chucVu) async {
    try {
      //isLoading(true);
      final response = await http.get(
        Uri.parse(Common.API + Common.UserSection),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          switch (chucVu) {
            case "PTHC":
            case "Section Manager":
              // Lọc theo section thông qua search API
              // Có 2 trường hợp đầu vào:
              // 1) section = "2100: PR1-PR1" (chuỗi đơn) => value phải là ["2100: PR1-PR1"]
              // 2) section = '["2100: PR1-PR1", "1234: ABC-XYZ"]' (chuỗi JSON list) => parse ra List
              List<String> sectionValues;
              final trimmed = section == null ? "" : section.trim();
              if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
                try {
                  final decoded = json.decode(trimmed);
                  if (decoded is List) {
                    sectionValues = decoded
                        .map((e) => e.toString().trim())
                        .toList();
                  } else {
                    sectionValues = [trimmed];
                  }
                } catch (_) {
                  sectionValues = [trimmed];
                }
              } else {
                sectionValues = [trimmed];
              }
              listSection.assignAll(sectionValues);
              break;
            case "Dept":
            case "Dept Manager":
              // Lọc theo dept thông qua search API
              listSection.assignAll(
                data
                    .where((item) => item.toString().contains(section ?? ""))
                    .map((item) => item.toString())
                    .toList(),
              );
              break;
            case "Director":
            case "General Director":
              if (section == null || section.isEmpty) {
                throw Exception('Section is required for Director role');
              }
              List<String> sectionValues = section.split(",");
              listSection.assignAll(
                data
                    .where((item) {
                      String itemString = item.toString();
                      return sectionValues.any(
                        (section) => itemString.contains(section),
                      );
                    })
                    .map((item) => item.toString())
                    .toList(),
              );
              break;
            case "Admin":
            case "Per":
              // Lấy toàn bộ danh sách (không lọc)
              listSection.addAll(data.map((item) => item.toString()).toList());
              break;
            default:
              // Lấy toàn bộ danh sách (không lọc theo section)
              listSection.add(section ?? "");
              break;
          }
          // listSection.assignAll(data.map((item) => item.toString()).toList());
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch section data: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  //  Từ chối phê duyệt nhiều
  Future<void> updateListContractReturnS(
    String userApprover,
    String reson,
  ) async {
    try {
      final contract = getSelectedItems();
      //fetchPTHCData();
      List<dynamic> notApproval = [];
      String sectionAp = "";
      if (contract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      // Deep clone selected contracts without requiring a copyWith method
      // notApproval = contract
      //     .map((item) => ApprenticeContract.fromJson(item.toJson()))
      //     .toList();
      for (int i = 0; i < contract.length; i++) {
        contract[i].vchRUserUpdate = userApprover;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        // lay thong tin phong
        sectionAp = contract[i].vchRCodeSection.toString();
        switch (contract[i].inTStatusId) {
          case 6:
            contract[i].dtMApproverChief = formatDateTime(DateTime.now());
            contract[i].useRApproverChief = userApprover;
            contract[i].nvchRApproverChief = reson;
            final json = contract[i].toJson();
            final contractCopy = ApprenticeContract.fromJson(json);
            notApproval.add(contractCopy);
            contract[i].biTApproverChief = false;

            contract[i].inTStatusId = 4;
            break;
          case 7:
            contract[i].dtMApproverManager = formatDateTime(DateTime.now());
            contract[i].useRApproverSectionManager = userApprover;
            contract[i].nvchRApproverManager = reson;
            contract[i].biTApproverSectionManager = false;
            final json = contract[i].toJson();
            final contractCopy = ApprenticeContract.fromJson(json);
            notApproval.add(contractCopy);
            contract[i].inTStatusId = 4;
            break;
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListApprentice}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract),
      );
      if (response.statusCode == 200) {
        // mail canh bao
        //Special case for section
        if (notApproval.isNotEmpty) {
          final specialSection = pthcList.firstWhere(
            (item) => item.section == "1120-1 : ADM-PER",
          );
          // Tối ưu lấy email cc và to, loại bỏ trùng lặp, kiểm tra null/empty một lần
          final sectionItems = pthcList.where(
            (item) => item.section == sectionAp,
          );
          final ccSet = <String>{};
          final toSet = <String>{};
          for (final item in sectionItems) {
            if (item.mailcc != null && item.mailcc!.trim().isNotEmpty) {
              ccSet.add(item.mailcc!.trim());
            }
            if (item.mailto != null && item.mailto!.trim().isNotEmpty) {
              toSet.add(item.mailto!.trim());
            }
          }
          if (specialSection.mailcc != null &&
              specialSection.mailcc!.trim().isNotEmpty) {
            ccSet.add(specialSection.mailcc!.trim());
          }
          if (specialSection.mailto != null &&
              specialSection.mailto!.trim().isNotEmpty) {
            toSet.add(specialSection.mailto!.trim());
          }
          final ccEmails = ccSet.join(';');
          final toEmails = toSet.join(';');
          final controlleruser = Get.put(DashboardControllerUser());
          controlleruser.SendMailCustom(
            '${specialSection.mailto};$toEmails',
            ccEmails,
            specialSection.mailbcc.toString(),
            notApproval,
            "Từ chối phê duyệt",
            userApprover,
            null,
          );
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('$e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateListContractReturnSPTHC(
    String userApprover,
    String reson,
  ) async {
    try {
      final contract = getSelectedItems();
      //fetchPTHCData();
      List<dynamic> notApproval = [];
      String sectionAp = "";
      if (contract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      // Deep clone selected contracts without requiring a copyWith method
      notApproval = contract
          .map((item) => ApprenticeContract.fromJson(item.toJson()))
          .toList();
      for (int i = 0; i < contract.length; i++) {
        contract[i].vchRUserUpdate = userApprover;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        // lay thong tin phong
        sectionAp = contract[i].vchRCodeSection.toString();
        //notApproval.add(contract[i]);
        if (contract[i].inTStatusId == 3) {
          contract[i].inTStatusId = 1;
        } else if (contract[i].inTStatusId == 4) {
          contract[i].inTStatusId = 3;
        } else if (contract[i].inTStatusId == 5) {
          contract[i].inTStatusId = 4;
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListApprentice}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract),
      );
      if (response.statusCode == 200) {
        // mail canh bao
        //Special case for section
        if (notApproval.isNotEmpty) {
          final specialSection = pthcList.firstWhere(
            (item) => item.section == "1120-1 : ADM-PER",
          );
          // Tối ưu lấy email cc và to, loại bỏ trùng lặp, kiểm tra null/empty một lần
          final sectionItems = pthcList.where(
            (item) => item.section == sectionAp,
          );
          final ccSet = <String>{};
          final toSet = <String>{};
          for (final item in sectionItems) {
            if (item.mailcc != null && item.mailcc!.trim().isNotEmpty) {
              ccSet.add(item.mailcc!.trim());
            }
            if (item.mailto != null && item.mailto!.trim().isNotEmpty) {
              toSet.add(item.mailto!.trim());
            }
          }
          if (specialSection.mailcc != null &&
              specialSection.mailcc!.trim().isNotEmpty) {
            ccSet.add(specialSection.mailcc!.trim());
          }
          if (specialSection.mailto != null &&
              specialSection.mailto!.trim().isNotEmpty) {
            toSet.add(specialSection.mailto!.trim());
          }
          final ccEmails = ccSet.join(';');
          final toEmails = toSet.join(';');
          final controlleruser = Get.put(DashboardControllerUser());

          controlleruser.SendMailCustom(
            '${specialSection.mailto};$toEmails',
            ccEmails,
            specialSection.mailbcc?.toString() ?? '',
            notApproval,
            "Từ chối xác nhận",
            userApprover,
            reson,
          );
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('$e');
    } finally {
      isLoading(false);
    }
  }
}
