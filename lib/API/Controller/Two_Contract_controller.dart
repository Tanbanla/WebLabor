import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_labor_contract/API/Controller/User_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/PTHC_Group.dart';
import 'package:web_labor_contract/class/Two_Contract.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_labor_contract/class/User_Approver.dart';

class DashboardControllerTwo extends GetxController {
  var dataList = <TwoContract>[].obs;
  var filterdataList = <TwoContract>[].obs;
  var originalList = <TwoContract>[].obs;
  var listSection = <String>[].obs;
  var selectedStatus = ''.obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;
  var pthcList = <PthcGroup>[].obs;
  // Multi-field query holders (new)
  final approverCodeQuery = ''.obs;
  final employeeIdQuery = ''.obs;
  final employeeNameQuery = ''.obs;
  final departmentQuery = ''.obs;
  final groupQuery = ''.obs;
  // Tracking import errors (file + messages) similar to Apprentice controller
  Rx<Uint8List?> lastImportErrorExcel = Rx<Uint8List?>(null);
  RxList<String> lastImportErrors = <String>[].obs;
  @override
  void onInit() {
    super.onInit();
    // fetchDummyData();
    //fetchDataBy(statusId: currentStatusId.value);
  }

  TwoContract? _byEmp(String employeeCode) {
    try {
      return dataList.firstWhere((e) => e.vchREmployeeId == employeeCode);
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

    bool matchesStatus(TwoContract item) {
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

    List<TwoContract> result = [];
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

  // so sanh du lieu
  void searchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.isEmpty) {
      filterdataList.assignAll(dataList);
    } else {
      filterdataList.assignAll(
        dataList.where((item) {
          final combined = [
            item.vchREmployeeId,
            item.vchREmployeeName,
            item.vchRNameSection,
            item.chRCostCenterName,
            item.chRPosition,
          ].where((e) => e != null).join(' ').toLowerCase();
          return combined.contains(lowerQuery);
        }),
      );
    }
  }

  // lay du lieu
  Future<void> fetchDummyData(String? section) async {
    try {
      isLoading(true);
      http.Response response;
      if (section == null || section.trim().isEmpty) {
        // Lấy toàn bộ danh sách (không lọc theo section)
        response = await http.get(
          Uri.parse(Common.API + Common.TwoGetAll),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        // Lọc theo section thông qua search API
        // Có 2 trường hợp đầu vào:
        // 1) section = "2100: PR1-PR1" (chuỗi đơn) => value phải là ["2100: PR1-PR1"]
        // 2) section = '["2100: PR1-PR1", "1234: ABC-XYZ"]' (chuỗi JSON list) => parse ra List
        List<String> sectionValues;
        final trimmed = section.trim();
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
        response = await http.post(
          Uri.parse(Common.API + Common.TwoSreachBy),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );
        // Debug log (có thể bỏ nếu không cần)
        // ignore: avoid_print
        print('fetchDummyData request: ${json.encode(requestBody)}');
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
          dataList.assignAll(data.map((e) => TwoContract.fromJson(e)).toList());
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
      // Build request body
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
          "value": ["3", "4"],
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
        Uri.parse(Common.API + Common.TwoSreachBy),
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
                        (a['inT_STATUS_ID'] == 3),
                  )
                  .map((contract) => TwoContract.fromJson(contract))
                  .toList(),
            );
            // dữ liệu gốc
            originalList.assignAll(
              data
                  .where(
                    (a) =>
                        (a['vchR_LEADER_EVALUTION'] == adid &&
                            a['inT_STATUS_ID'] == 4) ||
                        (a['inT_STATUS_ID'] == 3),
                  )
                  .map((contract) => TwoContract.fromJson(contract))
                  .toList(),
            );
          } else if (statusId == 'approval' &&
              adid != null &&
              adid.isNotEmpty) {
            // Local filtering for approval users
            final filtered = data.where((a) {
              switch (chucVu) {
                case "Section Manager":
                  return a['inT_STATUS_ID'] != null &&
                      [6].contains(a['inT_STATUS_ID']) &&
                      (a['userApproverSectionManager'] == adid ||
                          a['useR_APPROVER_SECTION_MANAGER'] == adid);
                case "Dept":
                case "Dept Manager":
                  return a['inT_STATUS_ID'] != null &&
                      [6, 7].contains(a['inT_STATUS_ID']) &&
                      (a['userApproverDeft'] == adid ||
                          a['useR_APPROVER_DEFT'] == adid ||
                          a['userApproverSectionManager'] == adid ||
                          a['useR_APPROVER_SECTION_MANAGER'] == adid);
                default:
                  return a['inT_STATUS_ID'] != null &&
                      [6, 7, 8].contains(a['inT_STATUS_ID']) &&
                      (a['userApproverDeft'] == adid ||
                          a['userApproverDirector'] == adid ||
                          a['useR_APPROVER_DEFT'] == adid ||
                          a['useR_APPROVER_DIRECTOR'] == adid ||
                          a['userApproverSectionManager'] == adid ||
                          a['useR_APPROVER_SECTION_MANAGER'] == adid);
              }
            }).toList();
            dataList.assignAll(
              filtered
                  .map((contract) => TwoContract.fromJson(contract))
                  .toList(),
            );
            originalList.assignAll(
              filtered
                  .map((contract) => TwoContract.fromJson(contract))
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
                  .map((contract) => TwoContract.fromJson(contract))
                  .toList(),
            );
            originalList.assignAll(
              filtered
                  .map((contract) => TwoContract.fromJson(contract))
                  .toList(),
            );
          } else {
            dataList.assignAll(
              data.map((contract) => TwoContract.fromJson(contract)).toList(),
            );
            // dữ liệu gốc
            originalList.assignAll(
              data.map((contract) => TwoContract.fromJson(contract)).toList(),
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

  // them danh gia
  Future<void> addTwoContract(
    TwoContract twocontract,
    String olded,
    String userUpdate,
  ) async {
    try {
      // bo sung cac truong con thieu
      final parsedEndDate = parseDateTime(twocontract.dtMEndDate);
      if (parsedEndDate != null &&
          parsedEndDate.difference(DateTime.now()).inDays.abs() <= 50) {
        throw Exception(tr('CheckTime1'));
      }
      twocontract.id = 0;
      twocontract.vchRUserCreate = userUpdate;
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
        //await fetchDataBy();
      } else {
        final error = json.decode(response.body);
        throw Exception('${error['message'] ?? response.body}');
      }
    } catch (e) {
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // update thông tin
  Future<void> updateTwoContract(
    TwoContract twocontract,
    String userUpdate,
  ) async {
    try {
      twocontract.vchRUserUpdate = userUpdate;
      twocontract.vchRCodeSection = twocontract.vchRNameSection;
      twocontract.dtMUpdate = formatDateTime(DateTime.now());

      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdateTwo}${twocontract.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract.toJson()),
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
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // update thông tin sửa đánh giá cuối cùng   // update thông tin
  Future<void> updateKetQuaTwoContract(
    TwoContract twocontract,
    String userUpdate,
    String ketquaOld,
  ) async {
    try {
      List<TwoContract> listOld = [];
      listOld.add(twocontract);
      twocontract.vchRUserUpdate = userUpdate;
      twocontract.dtMUpdate = formatDateTime(DateTime.now());

      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdateTwo}${twocontract.id}'),
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
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // Send mail phản hồi từ chối đánh giá
  Future<void> sendEmailReturn(
    TwoContract contract,
    String userApprover,
    String reason,
  ) async {
    try {
      //fetchPTHCData();
      List<dynamic> notApproval = [];
      final json = contract.toJson();
      final contractCopy = TwoContract.fromJson(json);

      notApproval.add(contractCopy);
      contract.biTNoReEmployment = false;
      if (contract.inTStatusId == 3) {
        contract.inTStatusId = 1;
      } else if (contract.inTStatusId == 4) {
        contract.inTStatusId = 3;
      } else if (contract.inTStatusId == 5) {
        contract.inTStatusId = 4;
      }
      if (notApproval.isNotEmpty) {
        final specialSection = pthcList.firstWhere(
          (item) => item.section == "1120-1 : ADM-PER",
        );
        // Lấy danh sách email cc theo section (nếu có)
        final sectionCc = pthcList
            .where((item) => item.section == contract.vchRCodeSection)
            .map((item) => item.mailcc)
            .where((e) => e != null && e.trim().isNotEmpty)
            .cast<String>()
            .toList();

        // Ghép các email cc, bỏ qua rỗng để không sinh ra ();
        final ccEmails = [
          ...sectionCc,
          if (specialSection.mailcc != null &&
              specialSection.mailcc!.trim().isNotEmpty)
            specialSection.mailcc?.trim(),
        ].join(';');
        final controlleruser = Get.put(DashboardControllerUser());
        controlleruser.SendMailCustom(
          specialSection.mailto.toString(),
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

  // udpate to list
  Future<void> updateListTwoContractPer(
    String userApprover,
    String userUpdate,
  ) async {
    try {
      //sau test delete
      // if (userApprover == "fujiokmi") {
      //   userApprover = 'vanug';
      // }
      // List<TwoContract> twocontract,
      final twocontract = getSelectedItems();
      if (twocontract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }

      // ⚡ PERFORMANCE OPTIMIZATION: Tạo Map để tìm kiếm O(1) thay vì O(n)
      // Tối ưu từ O(n²) xuống O(n) cho việc tìm kiếm originalList
      final Map<String, TwoContract> originalMap = {};

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

      for (int i = 0; i < twocontract.length; i++) {
        if ((twocontract[i].nvchRApproverPer?.isNotEmpty ?? false)) {
          // 🚀 Tìm kiếm O(1) thay vì O(n) với indexWhere
          TwoContract? original;

          // Tìm theo ID trước (ưu tiên)
          if (twocontract[i].id != null) {
            original = originalMap['id_${twocontract[i].id}'];
          }

          // Nếu không tìm thấy theo ID, tìm theo Employee ID
          if (original == null &&
              twocontract[i].vchREmployeeId?.isNotEmpty == true) {
            original = originalMap['emp_${twocontract[i].vchREmployeeId}'];
          }

          // Kiểm tra thay đổi nếu tìm thấy bản ghi gốc
          if (original != null) {
            final bool changed = original != twocontract[i];
            if (!changed) {
              // Không có thay đổi thực sự
              throw Exception(
                '${tr('CapNhat')} ${twocontract[i].vchREmployeeId}',
              );
            }
          }
        }
        twocontract[i].vchRUserUpdate = userUpdate;
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        twocontract[i].inTStatusId = 2;
        twocontract[i].biTApproverPer = true;
        twocontract[i].nvchRApproverPer = '';
        twocontract[i].useRApproverPer = userApprover;
        twocontract[i].vchRCodeApprover =
            'HD2N${DateFormat('yyyy-MM-dd').format(DateTime.now())}'; //formatDateTime(DateTime.now()).toString();
        twocontract[i].nvchRCompleteWork = 'OK';
        twocontract[i].nvchRUseful = 'OK';
        twocontract[i].nvchROther = 'OK';
        twocontract[i].vchRReasultsLeader = 'OK';
        twocontract[i].biTNoReEmployment = true;
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
        final controlleruser = Get.put(DashboardControllerUser());
        controlleruser.SendMail(
          '4',
          '$userApprover@brothergroup.net',
          '$userApprover@brothergroup.net',
          '$userApprover@brothergroup.net',
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(
          'Lỗi khi gửi dữ liệu lên server  ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  //update list cho PTHC va Leader
  Future<void> updateListTwoContractFill(
    String userApprover,
    String userUpdate,
    String chucVu,
    String userCase,
  ) async {
    try {
      List<dynamic> twocontract = [];
      final twocontractOld = getSelectedItems();
      if (twocontractOld.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      // lấy dữ liệu gốc để thực hiện
      twocontract = twocontractOld
          .map((item) => TwoContract.fromJson(item.toJson()))
          .toList();
      // So sánh những trường có ý nghĩa để xác định có thay đổi thực sự hay không
      bool _hasMeaningfulChanges(TwoContract original, TwoContract edited) {
        bool diffStr(String? a, String? b) => (a ?? '') != (b ?? '');
        bool diffBool(bool? a, bool? b) => (a ?? false) != (b ?? false);

        return
        // Điểm đánh giá/Leader
        diffStr(original.nvchRCompleteWork, edited.nvchRCompleteWork) ||
            diffStr(original.nvchRUseful, edited.nvchRUseful) ||
            diffStr(original.vchRNote, edited.vchRNote) ||
            diffStr(original.vchRReasultsLeader, edited.vchRReasultsLeader) ||
            // Tái tuyển dụng và lý do
            diffBool(original.biTNoReEmployment, edited.biTNoReEmployment) ||
            diffStr(original.nvchRNoReEmpoyment, edited.nvchRNoReEmpoyment) ||
            // Ghi chú
            diffStr(original.vchRNote, edited.vchRNote);
      }

      // ⚡ PERFORMANCE OPTIMIZATION: Tạo Map để tìm kiếm O(1) thay vì O(n)
      // Tối ưu từ O(n²) xuống O(n) cho việc tìm kiếm originalList
      final Map<String, TwoContract> originalMap = {};

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

      for (int i = 0; i < twocontract.length; i++) {
        // Nếu có nhập lý do (ít nhất 1 trong 3) thì kiểm tra xem có thay đổi gì so với dữ liệu gốc không
        if ((twocontract[i].nvchrApproverDeft?.isNotEmpty ?? false) ||
            (twocontract[i].nvchRApproverManager?.isNotEmpty ?? false) ||
            (twocontract[i].nvchRApproverDirector?.isNotEmpty ?? false)) {
          // 🚀 Tìm kiếm O(1) thay vì O(n) với indexWhere
          TwoContract? original;

          // Tìm theo ID trước (ưu tiên)
          if (twocontract[i].id != null) {
            original = originalMap['id_${twocontract[i].id}'];
          }

          // Nếu không tìm thấy theo ID, tìm theo Employee ID
          if (original == null &&
              twocontract[i].vchREmployeeId?.isNotEmpty == true) {
            original = originalMap['emp_${twocontract[i].vchREmployeeId}'];
          }

          // Kiểm tra thay đổi nếu tìm thấy bản ghi gốc
          if (original != null) {
            final bool hasChanges = _hasMeaningfulChanges(
              original,
              twocontract[i],
            );
            if (!hasChanges) {
              // Không có thay đổi thực sự
              throw Exception(
                '${tr('CapNhat')} ${twocontract[i].vchREmployeeId}',
              );
            }
          }
        }
        twocontract[i].vchRUserUpdate = userUpdate;
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        // cập nhật lại các lý do từ chối
        twocontract[i].nvchRApproverManager = '';
        twocontract[i].nvchRApproverDirector = '';
        twocontract[i].nvchrApproverDeft = '';
        twocontract[i].bitApproverDeft = true;
        twocontract[i].biTApproverSectionManager = true;
        twocontract[i].biTApproverDirector = true;

        switch (twocontract[i].inTStatusId) {
          case 3:
            twocontract[i].inTStatusId = 4;
            twocontract[i].nvchRPthcSection = userUpdate;
            twocontract[i].vchRLeaderEvalution = userApprover;
            twocontract[i].biTNoReEmployment = true;
            twocontract[i].biTApproverChief = true;
            twocontract[i].nvchRApproverChief = '';
            break;
          case 4:
            if (twocontract[i].nvchROther != 'OK' &&
                (twocontract[i].vchRNote == null ||
                    twocontract[i].vchRNote == "")) {
              throw Exception(
                '${tr('InputError1')} ${twocontract[i].vchREmployeeId}',
              );
            }
            if (twocontract[i].vchRReasultsLeader == 'NG' &&
                (twocontract[i].nvchRCompleteWork == 'OK' &&
                    twocontract[i].nvchRUseful == 'OK' &&
                    twocontract[i].nvchROther == 'OK')) {
              throw Exception(
                '${tr('InputError2')} ${twocontract[i].vchREmployeeId}',
              );
            }
            if (twocontract[i].vchRReasultsLeader != 'NG' &&
                (twocontract[i].nvchRCompleteWork != 'OK' ||
                    twocontract[i].nvchRUseful != 'OK' ||
                    twocontract[i].nvchROther != 'OK')) {
              throw Exception(
                '${tr('InputError3')} ${twocontract[i].vchREmployeeId}',
              );
            }
            if (twocontract[i].biTNoReEmployment == false &&
                (twocontract[i].nvchRNoReEmpoyment == null ||
                    twocontract[i].nvchRNoReEmpoyment == "")) {
              throw Exception(
                '${tr('InputError')} ${twocontract[i].vchREmployeeId}',
              );
            }
            if (chucVu == "Chief" || chucVu == "Expert") {
              twocontract[i].inTStatusId = 6;
              twocontract[i].vchRLeaderEvalution = userUpdate;
              twocontract[i].useRApproverChief = userUpdate;
              twocontract[i].dtMLeadaerEvalution = formatDateTime(
                DateTime.now(),
              );
              twocontract[i].biTApproverChief = true;
              twocontract[i].nvchRApproverChief = '';
              twocontract[i].useRApproverSectionManager = userApprover;
              twocontract[i].biTApproverSectionManager = true;
            } else if (chucVu == "Section Manager") {
              twocontract[i].inTStatusId = 7;
              twocontract[i].vchRLeaderEvalution = userUpdate;
              twocontract[i].useRApproverChief = userUpdate;
              twocontract[i].useRApproverSectionManager = userUpdate;
              twocontract[i].dtMApproverManager = formatDateTime(
                DateTime.now(),
              );
              twocontract[i].dtMLeadaerEvalution = formatDateTime(
                DateTime.now(),
              );
              twocontract[i].dtMApproverChief = formatDateTime(DateTime.now());
              twocontract[i].biTApproverChief = false;
              twocontract[i].nvchRApproverChief = '';
              twocontract[i].biTApproverSectionManager = true;
              twocontract[i].nvchRApproverManager = '';
              twocontract[i].userApproverDeft = userApprover;
              twocontract[i].bitApproverDeft = true;
            } else {
              twocontract[i].inTStatusId = 5;
              twocontract[i].vchRLeaderEvalution = userUpdate;
              twocontract[i].useRApproverChief = userApprover;
              twocontract[i].dtMLeadaerEvalution = formatDateTime(
                DateTime.now(),
              );
              twocontract[i].biTApproverChief = true;
              twocontract[i].nvchRApproverChief = '';
            }
            break;
          case 5:
            if (twocontract[i].biTApproverChief != true &&
                (twocontract[i].nvchRApproverChief == null ||
                    twocontract[i].nvchRApproverChief == "")) {
              throw Exception(
                '${tr('TuChoiPheDuyet')} ${twocontract[i].vchREmployeeId}',
              );
            }
            if (twocontract[i].biTApproverChief == false &&
                twocontract[i].nvchRApproverChief != "") {
              twocontract[i].inTStatusId = 4;
              twocontract[i].useRApproverChief = userUpdate;
              twocontract[i].dtMApproverChief = formatDateTime(DateTime.now());
            } else {
              switch (userCase) {
                case "ACC":
                  twocontract[i].inTStatusId = 7;
                  twocontract[i].useRApproverChief = userUpdate;
                  twocontract[i].useRApproverSectionManager = userApprover;
                  twocontract[i].dtMApproverChief = formatDateTime(
                    DateTime.now(),
                  );
                  twocontract[i].biTApproverSectionManager = true;
                  twocontract[i].dtMApproverManager = formatDateTime(
                    DateTime.now(),
                  );
                  twocontract[i].nvchRApproverManager = '';
                  twocontract[i].userApproverDeft = userApprover;
                  twocontract[i].bitApproverDeft = true;
                  break;
                default:
                  twocontract[i].inTStatusId = 6;
                  twocontract[i].useRApproverChief = userUpdate;
                  twocontract[i].useRApproverSectionManager = userApprover;
                  twocontract[i].dtMApproverChief = formatDateTime(
                    DateTime.now(),
                  );
                  twocontract[i].biTApproverSectionManager = true;
              }
            }
            break;
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
        if (chucVu == "PTHC") {
          final controlleruser = Get.put(DashboardControllerUser());
          controlleruser.SendMail(
            '4',
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
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  //update thong tin Phe duyet
  Future<void> updateListTwoContractApproval(
    String userApprover,
    String? nextApproverAdid,
  ) async {
    try {
      // List<TwoContract> twocontract,
      //fetchPTHCData();
      final twocontractOld = getSelectedItems();
      List<dynamic> notApproval = [];
      List<TwoContract> twocontract = [];
      String mailSend = "";
      String sectionAp = "";
      String PheDuyetMail = "";
      if (twocontractOld.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      // lấy dữ liệu gốc để thực hiện
      twocontract = twocontractOld
          .map((item) => TwoContract.fromJson(item.toJson()))
          .toList();
      for (int i = 0; i < twocontract.length; i++) {
        twocontract[i].vchRUserUpdate = userApprover;
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        // Tìm vị trí bắt đầu của phần dept
        List<String> parts = (twocontract[i].vchRCodeSection ?? "").split(": ");
        String prPart = parts[1];

        // Tách phần phòng ban
        List<String> prParts = prPart.split("-");
        String dept = prParts[0];
        // lay thong tin phong
        sectionAp = twocontract[i].vchRCodeSection.toString();
        switch (twocontract[i].inTStatusId) {
          case 6:
            twocontract[i].dtMApproverManager = formatDateTime(DateTime.now());
            twocontract[i].useRApproverSectionManager = userApprover;
            if (twocontract[i].biTApproverSectionManager != false) {
              twocontract[i].inTStatusId = 7;
              twocontract[i].bitApproverDeft = true;
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
              twocontract[i].userApproverDeft = mailSend.split('@')[0];
            } else {
              if ((twocontract[i].nvchRApproverManager?.isEmpty ?? true)) {
                throw Exception(
                  '${tr('NotApproval')} ${twocontract[i].vchREmployeeName}',
                );
              }
              final json = twocontract[i].toJson();
              final contractCopy = TwoContract.fromJson(json);
              notApproval.add(contractCopy);
              twocontract[i].inTStatusId = 4;
            }
            break;
          case 7:
            twocontract[i].dtmApproverDeft = formatDateTime(DateTime.now());
            twocontract[i].userApproverDeft = userApprover;
            if (twocontract[i].bitApproverDeft != false) {
              twocontract[i].inTStatusId = 8;
              twocontract[i].biTApproverDirector = true;
              mailSend = await NextApprovel(
                section: "",
                chucVu: "Director",
                dept: dept,
              );
              twocontract[i].useRApproverDirector = mailSend.split('@')[0];
            } else {
              if ((twocontract[i].nvchrApproverDeft?.isEmpty ?? true)) {
                throw Exception(
                  '${tr('NotApproval')} ${twocontract[i].vchREmployeeName}',
                );
              }
              final json = twocontract[i].toJson();
              final contractCopy = TwoContract.fromJson(json);
              notApproval.add(contractCopy);
              twocontract[i].inTStatusId = 4;
              // Thêm email của quản lý phòng ban vào danh sách phê duyệt
              final chief = twocontract[i].useRApproverChief;
              final manager = twocontract[i].useRApproverSectionManager;
              // Thêm email của quản lý phòng ban vào danh sách phê duyệt
              if (chief != null && chief.isNotEmpty) {
                final email =
                    '$chief@brothergroup.net;$manager@brothergroup.net';
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
          case 8:
            twocontract[i].dtMApproverDirector = formatDateTime(DateTime.now());
            twocontract[i].useRApproverDirector = userApprover;
            if (twocontract[i].biTApproverDirector != false) {
              twocontract[i].inTStatusId = 9;
            } else {
              if ((twocontract[i].nvchRApproverDirector?.isEmpty ?? true)) {
                throw Exception(
                  '${tr('NotApproval')} ${twocontract[i].vchREmployeeName}',
                );
              }
              final json = twocontract[i].toJson();
              final contractCopy = TwoContract.fromJson(json);
              notApproval.add(contractCopy);
              twocontract[i].inTStatusId = 4;
              // Thêm email của quản lý phòng ban vào danh sách phê duyệt
              {
                final existingEmails = PheDuyetMail.split(';')
                    .map((e) => e.trim().toLowerCase())
                    .where((e) => e.isNotEmpty)
                    .toSet();

                void appendIfNotExists(String? user) {
                  if (user == null || user.trim().isEmpty) return;
                  final email = '${user.trim()}@brothergroup.net';
                  if (!existingEmails.contains(email.toLowerCase())) {
                    PheDuyetMail += '$email;';
                    existingEmails.add(email.toLowerCase());
                  }
                }

                appendIfNotExists(twocontract[i].useRApproverSectionManager);
                appendIfNotExists(twocontract[i].useRApproverChief);
                appendIfNotExists(twocontract[i].userApproverDeft);
              }
            }
            break;
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
        final controlleruser = Get.put(DashboardControllerUser());
        //mail phe duyet
        if (mailSend != '') {
          //controlleruser.SendMail('6', mailSend, mailSend, mailSend);
          // k mo vi mo se gui cho quan ly cac phong
          // controlleruser.SendMail(
          //   '6',
          //   "vietdo@brothergroup.net,vanug@brothergroup.net,tuanho@brothergroup.net,huyenvg@brothergroup.net, hoaiph@brothergroup.net",
          //   "nguyenduy.khanh@brother-bivn.com.vn;hoangviet.dung@brother-bivn.com.vn",
          //   "vuduc.hai@brother-bivn.com.vn",
          // );
        }
        // mail canh bao
        //Special case for section "1120-1 : ADM-PER"
        if (notApproval.isNotEmpty) {
          final specialSection = pthcList.firstWhere(
            (item) => item.section == "1120-1 : ADM-PER",
          );
          // Lấy danh sách email cc theo section (nếu có)
          final sectionCc = pthcList
              .where((item) => item.section == sectionAp)
              .map((item) => item.mailcc)
              .where((e) => e != null && e.trim().isNotEmpty)
              .cast<String>()
              .toList();

          // Ghép các email cc, bỏ qua rỗng để không sinh ra ();
          final ccEmails = [
            ...sectionCc,
            if (specialSection.mailcc != null &&
                specialSection.mailcc!.trim().isNotEmpty)
              specialSection.mailcc?.trim(),
          ].join(';');
          controlleruser.SendMailCustom(
            specialSection.mailto.toString(),
            '$ccEmails;$PheDuyetMail',
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
      showError('Failed to update two contract: $e');
      rethrow;
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
        //await fetchDataBy();
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

  // delete list
  Future<void> deleteListTwoContract() async {
    try {
      isLoading(true);
      final twocontract = getSelectedItems();

      if (twocontract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }

      // Lấy danh sách ID từ các item được chọn
      final ids = twocontract.map((contract) => contract.id).toList();

      final endpoint = Common.DeleteTwoMultiID;
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
      showError('Failed to delete twoContract: $e');
    } finally {
      isLoading(false);
    }
  }

  // import file
  Future<void> importExcelMobileTwoContract(
    File file,
    String userUpdate,
  ) async {
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
          ..dtMJoinDate = row[9]?.value?.toString()
          ..dtMEndDate = row[12]?.value?.toString()
          ..fLGoLeaveLate = row[13]?.value != null
              ? double.tryParse(row[13]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLPaidLeave = row[14]?.value != null
              ? double.tryParse(row[14]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..fLNotPaidLeave = row[15]?.value != null
              ? double.tryParse(row[15]!.value.toString()) ?? 0
              : 0
          ..fLNotLeaveDay = row[16]?.value != null
              ? double.tryParse(row[16]!.value.toString()) ?? 0
              : 0
          ..inTViolation = row[17]?.value != null
              ? int.tryParse(row[17]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation = row[18]?.value.toString() ?? ''
          ..nvchRCompleteWork //= row[17]!.value.toString()
          ..nvchRUseful //= row[18]!.value.toString()
          ..nvchROther //= row[19]!.value.toString()
          ..vchRReasultsLeader //= row[20]!.value.toString()
          ..biTNoReEmployment = true
          ..nvchRNoReEmpoyment //= row[23]!.value.toString()
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
          ..vchRNote //= row[21]!.value.toString()
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
            parsedEndDate.difference(DateTime.now()).inDays.abs() <= 50) {
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
      //await fetchDataBy();
    } catch (e) {
      showError('Import failed: $e');
      rethrow;
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
      final List<TwoContract> importedTwoContract = [];
      int _i = 19;
      // Start from row 1 (skip header row) and process until empty row
      while (rows[_i][2]?.value?.toString().isEmpty == false) {
        final row = rows[_i];
        // Create and populate
        final twocontract = TwoContract()
          ..id = 0
          ..vchRCodeApprover
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
          ..dtMJoinDate = row[9]?.value?.toString()
          ..dtMEndDate = row[12]?.value?.toString()
          ..fLGoLeaveLate = row[13]?.value != null
              ? double.tryParse(row[13]!.value.toString()) ?? 0
              : 0 //double.parse(row[11]!.value.toString())
          ..fLPaidLeave = row[14]?.value != null
              ? double.tryParse(row[14]!.value.toString()) ?? 0
              : 0 //double.parse(row[12]!.value.toString())
          ..fLNotPaidLeave = row[15]?.value != null
              ? double.tryParse(row[15]!.value.toString()) ?? 0
              : 0
          ..fLNotLeaveDay = row[16]?.value != null
              ? double.tryParse(row[16]!.value.toString()) ?? 0
              : 0
          ..inTViolation = row[17]?.value != null
              ? int.tryParse(row[17]!.value.toString()) ?? 0
              : 0
          ..nvarchaRViolation = row[18]?.value.toString() ?? ''
          ..nvchRCompleteWork //= row[17]!.value.toString()
          ..nvchRUseful //= row[18]!.value.toString()
          ..nvchROther //= row[19]!.value.toString()
          ..vchRReasultsLeader //= row[20]!.value.toString()
          ..biTNoReEmployment = true
          ..nvchRNoReEmpoyment //= row[23]!.value.toString()
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
          ..vchRNote //= row[21]!.value.toString()
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
            parsedEndDate.difference(DateTime.now()).inDays.abs() <= 50) {
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
      //await fetchDataBy();
    } catch (e) {
      showError('Import failed: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // hàm import dữ liệu từ excel cho Leader
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
      // 4. Refresh data
      final List<TwoContract> importedTwoContract = [];
      final List<Map<String, dynamic>> errorRows = [];
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
            'employeeId': '',
            'reason': 'Thiếu mã nhân viên',
          });
          lastImportErrors.add('Row ${_i + 1}: Thiếu mã nhân viên');
          _i++;
          continue;
        }

        // Tìm dữ liệu hiện có từ filterdataList và dataList
        final existingDataFromFilter = filterdataList.firstWhere(
          (item) => item.vchREmployeeId == employeeId,
          orElse: () => TwoContract(),
        );

        final existingDataFromData = dataList.firstWhere(
          (item) => item.vchREmployeeId == employeeId,
          orElse: () => TwoContract(),
        );

        // Ưu tiên dữ liệu từ filterdataList, nếu không có thì dùng từ dataList
        final existingData = existingDataFromFilter.id != 0
            ? existingDataFromFilter
            : existingDataFromData;

        // Create and populate - giữ nguyên các trường khác từ dữ liệu hiện có
        final twocontract = TwoContract()
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
          ..fLPaidLeave = existingData.fLPaidLeave
          ..fLNotPaidLeave = existingData.fLNotPaidLeave
          ..fLNotLeaveDay = existingData.fLNotLeaveDay
          ..inTViolation = existingData.inTViolation
          ..nvarchaRViolation = existingData.nvarchaRViolation
          // CHỈ CẬP NHẬT các trường từ file Excel
          ..nvchRCompleteWork =
              row[19]?.value?.toString() ?? existingData.nvchRCompleteWork
          ..nvchRUseful = row[20]?.value?.toString() ?? existingData.nvchRUseful
          ..nvchROther = row[21]?.value?.toString() ?? existingData.nvchROther
          ..vchRReasultsLeader =
              row[22]?.value?.toString() ?? existingData.vchRReasultsLeader
          ..biTNoReEmployment = row[23]?.value != null
              ? (row[23]!.value.toString().toLowerCase() == 'true' ||
                    row[23]!.value.toString() == '1')
              : existingData.biTNoReEmployment
          ..nvchRNoReEmpoyment =
              row[24]?.value?.toString() ?? existingData.nvchRNoReEmpoyment
          // Giữ nguyên các trường khác từ dữ liệu hiện có
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
          continue; // Skip invalid rows
        }
        if (!await checkEmployeeExists(twocontract.vchREmployeeId!)) {
          errorRows.add({
            'row': _i + 1,
            'employeeId': employeeId,
            'reason': 'Nhân viên không tồn tại',
          });
          lastImportErrors.add('Row ${_i + 1}: Nhân viên không tồn tại');
          _i++;
          continue; // Skip invalid rows
        }
        final parsedEndDate = parseDateTime(twocontract.dtMEndDate);
        if (parsedEndDate != null &&
            parsedEndDate.difference(DateTime.now()).inDays.abs() <= 50) {
          errorRows.add({
            'row': _i + 1,
            'employeeId': employeeId,
            'reason': 'Hạn đánh giá quá gần (<=50 ngày)',
          });
          lastImportErrors.add(
            'Row ${_i + 1}: Hạn đánh giá quá gần (<=50 ngày)',
          );
          _i++;
          continue; // Skip invalid rows
        }
        importedTwoContract.add(twocontract);
        _i++;
      }
      // 5. Send to API
      if (importedTwoContract.isEmpty) {
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
      showError('Import failed: $e');
      rethrow;
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
          // Employee exists
          return jsonData['data'] != null;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      showError('Failed to check employee: $e');
      return false;
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

  // dien danh gia
  void updateOther(String employeeCode, String status) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!status.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.nvchRCompleteWork == 'OK' && item.nvchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.nvchROther = status;
    if (status == 'OK') {
      item.vchRNote = '';
    }
    dataList.refresh();
    filterdataList.refresh();
  }

  // ghi chu
  void updateNote(String employeeCode, String status) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    item.vchRNote = status;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateEvaluationStatus(String employeeCode, String status) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    item.vchRReasultsLeader = status;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateRehireStatus(String employeeCode, bool value) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    item.biTNoReEmployment = value;
    if (value == true) {
      item.nvchRNoReEmpoyment = '';
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

  void updateCongViec(String employeeCode, String reason) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!reason.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.nvchROther == 'OK' && item.nvchRUseful == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.nvchRCompleteWork = reason;
    dataList.refresh();
    filterdataList.refresh();
  }

  void updateUserFull(String employeeCode, String reason) {
    final item = _byEmp(employeeCode);
    if (item == null) return;
    if (!reason.contains('OK')) {
      item.vchRReasultsLeader = 'NG';
    } else if (item.nvchRCompleteWork == 'OK' && item.nvchROther == 'OK') {
      item.vchRReasultsLeader = 'OK';
    }
    item.nvchRUseful = reason;
    dataList.refresh();
    filterdataList.refresh();
  }

  // Các thông tin lưu ở Phê duyệt
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
      case 8:
        item.nvchRApproverDirector = reason;
        break;
      default:
        break;
    }
    dataList.refresh();
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
      case 8:
        item.biTApproverDirector = value;
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
  Future<void> fetchSectionList() async {
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
          listSection.assignAll(data.map((item) => item.toString()).toList());
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

  //  Từ chối phê duyệt nhiều của Apporver
  Future<void> updateListTwoContractReturnS(
    String userApprover,
    String reson,
  ) async {
    try {
      final twocontract = getSelectedItems();
      List<dynamic> notApproval = [];
      String sectionAp = "";
      if (twocontract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      for (int i = 0; i < twocontract.length; i++) {
        twocontract[i].vchRUserUpdate = userApprover;
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        // lay thong tin phong
        sectionAp = twocontract[i].vchRCodeSection.toString();
        switch (twocontract[i].inTStatusId) {
          case 6:
            twocontract[i].dtMApproverManager = formatDateTime(DateTime.now());
            twocontract[i].useRApproverSectionManager = userApprover;
            twocontract[i].nvchRApproverManager = reson;
            twocontract[i].biTApproverSectionManager = false;
            final json = twocontract[i].toJson();
            final contractCopy = TwoContract.fromJson(json);
            notApproval.add(contractCopy);
            twocontract[i].inTStatusId = 4;
            break;
          case 7:
            twocontract[i].dtmApproverDeft = formatDateTime(DateTime.now());
            twocontract[i].userApproverDeft = userApprover;
            twocontract[i].nvchrApproverDeft = reson;
            twocontract[i].bitApproverDeft = false;
            final json = twocontract[i].toJson();
            final contractCopy = TwoContract.fromJson(json);
            notApproval.add(contractCopy);
            twocontract[i].inTStatusId = 4;
            break;
          case 8:
            twocontract[i].dtMApproverDirector = formatDateTime(DateTime.now());
            twocontract[i].useRApproverDirector = userApprover;
            twocontract[i].nvchRApproverDirector = reson;
            twocontract[i].biTApproverDirector = false;
            final json = twocontract[i].toJson();
            final contractCopy = TwoContract.fromJson(json);
            notApproval.add(contractCopy);
            twocontract[i].inTStatusId = 4;
            break;
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
        final controlleruser = Get.put(DashboardControllerUser());
        // mail canh bao
        //Special case for section "1120-1 : ADM-PER"
        if (notApproval.isNotEmpty) {
          final specialSection = pthcList.firstWhere(
            (item) => item.section == "1120-1 : ADM-PER",
          );
          // Lấy danh sách email cc theo section (nếu có)
          final sectionCc = pthcList
              .where((item) => item.section == sectionAp)
              .map((item) => item.mailcc)
              .where((e) => e != null && e.trim().isNotEmpty)
              .cast<String>()
              .toList();

          // Ghép các email cc, bỏ qua rỗng để không sinh ra ();
          final ccEmails = [
            ...sectionCc,
            if (specialSection.mailcc != null &&
                specialSection.mailcc!.trim().isNotEmpty)
              specialSection.mailcc?.trim(),
          ].join(';');
          controlleruser.SendMailCustom(
            specialSection.mailto.toString(),
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
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  //  Từ chối phê duyệt nhiều của PTHC
  Future<void> updateListTwoContractReturnSPTHC(
    String userApprover,
    String reson,
  ) async {
    try {
      final twocontract = getSelectedItems();
      List<dynamic> notApproval = [];
      String sectionAp = "";
      if (twocontract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      notApproval = twocontract
          .map((item) => TwoContract.fromJson(item.toJson()))
          .toList();
      for (int i = 0; i < twocontract.length; i++) {
        twocontract[i].vchRUserUpdate = userApprover;
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        // lay thong tin phong
        sectionAp = twocontract[i].vchRCodeSection.toString();
        if (twocontract[i].inTStatusId == 3) {
          twocontract[i].inTStatusId = 1;
        } else if (twocontract[i].inTStatusId == 4) {
          twocontract[i].inTStatusId = 3;
        } else if (twocontract[i].inTStatusId == 5) {
          twocontract[i].inTStatusId = 4;
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListTwo}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract),
      );
      if (response.statusCode == 200) {
        //await fetchDataBy();
        final controlleruser = Get.put(DashboardControllerUser());
        // mail canh bao
        //Special case for section "1120-1 : ADM-PER"
        if (notApproval.isNotEmpty) {
          final specialSection = pthcList.firstWhere(
            (item) => item.section == "1120-1 : ADM-PER",
          );
          // Lấy danh sách email cc theo section (nếu có)
          final sectionCc = pthcList
              .where((item) => item.section == sectionAp)
              .map((item) => item.mailcc)
              .where((e) => e != null && e.trim().isNotEmpty)
              .cast<String>()
              .toList();

          // Ghép các email cc, bỏ qua rỗng để không sinh ra ();
          final ccEmails = [
            ...sectionCc,
            if (specialSection.mailcc != null &&
                specialSection.mailcc!.trim().isNotEmpty)
              specialSection.mailcc?.trim(),
          ].join(';');
          controlleruser.SendMailCustom(
            specialSection.mailto.toString(),
            ccEmails,
            specialSection.mailbcc.toString(),
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
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }
}
