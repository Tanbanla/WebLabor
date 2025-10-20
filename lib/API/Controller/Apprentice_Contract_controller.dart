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
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;
  var pthcList = <PthcGroup>[].obs;

  RxString currentStatusId = "1".obs;

  @override
  void onInit() {
    super.onInit();
    //fetchDummyData();
    //fetchDataBy(statusId: currentStatusId.value);
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
        case 'Manager':
          return id == 6;
        case 'Dept':
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
          cloumn = "USER_APPROVER_DEFT";
          break;
        case "8":
          cloumn = "USER_APPROVER_DIRECTOR";
          break;
      }
      // Build request body
      final filters = [
        if (statusId == 'approval')
          {
            "field": "INT_STATUS_ID",
            "value": ["6", "7", "8"],
            "operator": "IN",
            "logicType": "AND",
          }
        else if (statusId == 'PTHC')
          {
            "field": "INT_STATUS_ID",
            "value": ["3", "4","5"],
            "operator": "IN",
            "logicType": "AND",
          }
        else
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
        if (adid != null && adid.isNotEmpty && statusId != 'approval')
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
          // dữ liệu gốc
          originalList.assignAll(
            data
                .map((contract) => ApprenticeContract.fromJson(contract))
                .toList(),
          );
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
      if (contract.inTStatusId == 3) {
        contract.inTStatusId = 1;
      } else if (contract.inTStatusId == 4) {
        contract.inTStatusId = 3;
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
      for (int i = 0; i < contract.length; i++) {
        // Nếu có nhập lý do (ít nhất 1 trong 3) thì kiểm tra xem có thay đổi gì so với dữ liệu gốc không
        if ((contract[i].nvchRApproverPer?.isNotEmpty ?? false)) {
          // Tìm bản ghi gốc trong originalList (ưu tiên so sánh theo id, fallback theo mã NV)
          final originalIndex = originalList.indexWhere(
            (d) =>
                (contract[i].id != null && d.id == contract[i].id) ||
                (d.vchREmployeeId == contract[i].vchREmployeeId),
          );
          if (originalIndex != -1) {
            final original = originalList[originalIndex];
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
          '$userApprover@brothergroup.net',
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
  ) async {
    try {
      final contract = getSelectedItems();
      if (contract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      // So sánh những trường có ý nghĩa để xác định có thay đổi thực sự hay không
      bool _hasMeaningfulChanges(
        ApprenticeContract original,
        ApprenticeContract edited,
      ) {
        bool diffStr(String? a, String? b) => (a ?? '') != (b ?? '');
        bool diffBool(bool? a, bool? b) => (a ?? false) != (b ?? false);

        return
        // Điểm đánh giá/Leader
        diffStr(original.vchRLyThuyet, edited.vchRLyThuyet) ||
            diffStr(original.vchRThucHanh, edited.vchRThucHanh) ||
            diffStr(original.vchRCompleteWork, edited.vchRCompleteWork) ||
            diffStr(original.vchRLearnWork, edited.vchRLearnWork) ||
            diffStr(original.vchRThichNghi, edited.vchRThichNghi) ||
            diffStr(original.vchRUseful, edited.vchRUseful) ||
            diffStr(original.vchRContact, edited.vchRContact) ||
            diffStr(original.vcHNeedViolation, edited.vcHNeedViolation) ||
            diffStr(original.vchRReasultsLeader, edited.vchRReasultsLeader) ||
            // Tái tuyển dụng và lý do
            diffBool(original.biTNoReEmployment, edited.biTNoReEmployment) ||
            diffStr(original.nvchRNoReEmpoyment, edited.nvchRNoReEmpoyment) ||
            // Ghi chú
            diffStr(original.vchRNote, edited.vchRNote);
      }

      for (int i = 0; i < contract.length; i++) {
        if ((contract[i].nvchRApproverChief?.isNotEmpty ?? false) ||
            (contract[i].nvchRApproverManager?.isNotEmpty ?? false)) {
          // Tìm bản ghi gốc trong dataList (ưu tiên so sánh theo id, fallback theo mã NV)
          final originalIndex = originalList.indexWhere(
            (d) =>
                (contract[i].id != null && d.id == contract[i].id) ||
                (d.vchREmployeeId == contract[i].vchREmployeeId),
          );
          if (originalIndex != -1) {
            final original = originalList[originalIndex];
            final bool hasChanges = _hasMeaningfulChanges(
              original,
              contract[i],
            );
            if (!hasChanges) {
              // Không có thay đổi thực sự
              throw Exception('${tr('CapNhat')} ${contract[i].vchREmployeeId}');
            }
          }
        }
        contract[i].vchRUserUpdate = userUpdate;
        contract[i].dtMUpdate = formatDateTime(DateTime.now());
        contract[i].biTApproverChief = true;
        contract[i].biTApproverSectionManager = true;
        // cập nhật lại các lý do từ chối
        contract[i].nvchRApproverChief = '';
        contract[i].nvchRApproverManager = '';
        contract[i].nvchRApproverDirector = '';
        contract[i].biTApproverChief = true;
        contract[i].biTApproverSectionManager = true;
        contract[i].biTApproverDirector = true;
        switch (contract[i].inTStatusId) {
          case 3:
            contract[i].inTStatusId = 4;
            contract[i].nvchRPthcSection = userUpdate;
            contract[i].vchRLeaderEvalution = userApprover;
            contract[i].biTNoReEmployment = true;
          case 4:
            if (contract[i].vchRReasultsLeader != 'OK' &&
                (contract[i].vchRLyThuyet == 'OK' &&
                    contract[i].vchRThucHanh == 'OK' &&
                    contract[i].vchRCompleteWork == 'OK' &&
                    contract[i].vchRLearnWork == 'OK' &&
                    contract[i].vchRThichNghi == 'OK' &&
                    contract[i].vchRUseful == 'OK' &&
                    contract[i].vchRContact == 'OK' &&
                    contract[i].vcHNeedViolation == 'OK' &&
                    (contract[i].vchRNote == '' ||
                        contract[i].vchRNote == null))) {
              throw Exception(
                '${tr('InputError1')} ${contract[i].vchREmployeeId}',
              );
            }
            if (contract[i].biTNoReEmployment == false &&
                (contract[i].nvchRNoReEmpoyment == null ||
                    contract[i].nvchRNoReEmpoyment == "")) {
              throw Exception(
                '${tr('InputError')} ${contract[i].vchREmployeeId}',
              );
            }
            contract[i].inTStatusId = 5;
            contract[i].vchRLeaderEvalution = userUpdate;
            contract[i].useRApproverChief = userApprover;
            contract[i].dtMLeadaerEvalution = formatDateTime(DateTime.now());
          case 5:
            contract[i].inTStatusId = 6;
            contract[i].useRApproverSectionManager = userApprover;
            contract[i].dtMApproverChief = formatDateTime(DateTime.now());
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
        final controlleruser = Get.put(DashboardControllerUser());
        controlleruser.SendMail(
          '2',
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
  Future<void> updateListApprenticeContractApproval(String userApprover) async {
    try {
      final contract = getSelectedItems();
      //fetchPTHCData();
      List<dynamic> notApproval = [];
      String mailSend = "";
      String sectionAp = "";
      String PheDuyetMail = "";
      if (contract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
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
            contract[i].dtMApproverChief = formatDateTime(DateTime.now());
            contract[i].useRApproverChief = userApprover;
            if (contract[i].biTApproverChief == true) {
              contract[i].inTStatusId = 7;
              mailSend = await NextApprovel(
                section: contract[i].vchRCodeSection,
                chucVu: "Dept Manager",
                dept: dept,
              );
            } else {
              if ((contract[i].nvchRApproverChief?.isEmpty ?? true)) {
                throw Exception(
                  '${tr('NotApproval')} ${contract[i].vchREmployeeName}',
                );
              }
              final json = contract[i].toJson();
              final contractCopy = ApprenticeContract.fromJson(json);
              notApproval.add(contractCopy);
              contract[i].inTStatusId = 4;
            }
          case 7:
            //xu ly khi xong
            //mailSend = "k";
            //
            contract[i].dtMApproverManager = formatDateTime(DateTime.now());
            contract[i].useRApproverSectionManager = userApprover;
            if (contract[i].biTApproverSectionManager == true) {
              contract[i].inTStatusId = 9;
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
        final controlleruser = Get.put(DashboardControllerUser());
        //mail phe duyet
        if (mailSend != '') {
          controlleruser.SendMail('5', mailSend, mailSend, mailSend);
          // controlleruser.SendMail(
          //   '5',
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
          ..nvchrApproverDeft
          ;
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
          ..nvchrApproverDeft
          ;
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
      case 6:
        item.nvchRApproverChief = reason;
        break;
      case 7:
        item.nvchRApproverManager = reason;
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
      case 6:
        item.biTApproverChief = value;
        break;
      case 7:
        item.biTApproverSectionManager = value;
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
          return (jsonData['data'] as List)
              .map((item) => ApproverUser.fromJson(item).chREmployeeMail)
              .where((email) => email != null && email.isNotEmpty)
              .join(';');
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
          case 7:
            contract[i].dtMApproverManager = formatDateTime(DateTime.now());
            contract[i].useRApproverSectionManager = userApprover;
            contract[i].nvchRApproverManager = reson;
            contract[i].biTApproverSectionManager = false;
            final json = contract[i].toJson();
            final contractCopy = ApprenticeContract.fromJson(json);
            notApproval.add(contractCopy);
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
        }
      }
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdataListApprentice}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contract),
      );
      if (response.statusCode == 200) {
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
            specialSection.mailto?.toString() ?? '',
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
