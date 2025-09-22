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
  var listSection = <String>[].obs;
  var selectedStatus = ''.obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  var isLoadingExport = false.obs;
  var pthcList = <PthcGroup>[].obs;
  @override
  void onInit() {
    super.onInit();
    // fetchDummyData();
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
  // Filter by approver code (DotDanhGia)
  void filterByApproverCode(String query) {
    if (query.isEmpty) {
      refreshFilteredList();
      return;
    }

    final filteredList = dataList.where((item) {
      final code = item.vchRCodeApprover?.toLowerCase() ?? '';
      return code.contains(query.toLowerCase());
    }).toList();

    filterdataList.value = filteredList;
  }

  // Filter by employee ID
  void filterByEmployeeId(String query) {
    if (query.isEmpty) {
      refreshFilteredList();
      return;
    }

    final filteredList = dataList.where((item) {
      final id = item.vchREmployeeId?.toLowerCase() ?? '';
      return id.contains(query.toLowerCase());
    }).toList();

    filterdataList.value = filteredList;
  }

  // Filter by employee name
  void filterByEmployeeName(String query) {
    if (query.isEmpty) {
      refreshFilteredList();
      return;
    }

    final filteredList = dataList.where((item) {
      final name = item.vchREmployeeName?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    filterdataList.value = filteredList;
  }

  // Filter by department
  void filterByDepartment(String query) {
    if (query.isEmpty) {
      refreshFilteredList();
      return;
    }

    final filteredList = dataList.where((item) {
      final department = item.vchRNameSection?.toLowerCase() ?? '';
      return department.contains(query.toLowerCase());
    }).toList();

    filterdataList.value = filteredList;
  }

  // Filter by group
  void filterByGroup(String query) {
    if (query.isEmpty) {
      refreshFilteredList();
      return;
    }
    final filteredList = dataList.where((item) {
      final group = item.chRCostCenterName?.toLowerCase() ?? '';
      return group.contains(query.toLowerCase());
    }).toList();

    filterdataList.value = filteredList;
  }
  // Helper method to reset the filtered list to the original data
  void refreshFilteredList() {
    filterdataList.value = List.from(dataList);
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
  void filterByStatus(String query) {
    if (query.isEmpty) {
      refreshFilteredList();
      return;
    }

    final filteredList = dataList.where((item) {
      final statusId = item.inTStatusId;
      final statusText = getStatusText(statusId);
      return statusText.toLowerCase().contains(query.toLowerCase());
    }).toList();

    filterdataList.value = filteredList;
  }

  // Helper method to convert status ID to text
  String getStatusText(int? statusId) {
    switch (statusId) {
      case 1:
        return 'New';
      case 2:
        return 'Per';
      case 3:
        return 'PTHC';
      case 4:
        return 'Leader';
      case 6:
        return 'Manager';
      case 7:
        return 'Dept';
      case 8:
        return 'Director';
      case 9:
        return 'Done';
      default:
        return 'Unknown';
    }
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

  Future<void> fetchDataBy({
    String? statusId,
    String? section,
    String? adid,
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
        case "6":
          cloumn = "USER_APPROVER_CHIEF";
          break;
        case "7":
          cloumn = "USER_APPROVER_SECTION_MANAGER";
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
            "value": ["3", "4"],
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
            "operator": "LIKE",
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
        Uri.parse(Common.API + Common.TwoSreachBy),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // Lấy dữ liệu từ phần data.data (theo cấu trúc response)
          final List<dynamic> data = jsonData['data']['data'] ?? [];

          dataList.assignAll(
            data.map((contract) => TwoContract.fromJson(contract)).toList(),
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

  // them danh gia
  Future<void> addTwoContract(
    TwoContract twocontract,
    String olded,
    String userUpdate,
  ) async {
    try {
      // bo sung cac truong con thieu
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
      twocontract.vchRNameSection = twocontract.vchRCodeSection;
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

  // udpate to list
  Future<void> updateListTwoContractPer(
    String userApprover,
    String userUpdate,
  ) async {
    try {
      //sau test delete
      if (userApprover == "fujiokmi") {
        userApprover = 'vanug';
      }
      // List<TwoContract> twocontract,
      final twocontract = getSelectedItems();
      if (twocontract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      for (int i = 0; i < twocontract.length; i++) {
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
  ) async {
    try {
      final twocontract = getSelectedItems();
      if (twocontract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
      for (int i = 0; i < twocontract.length; i++) {
        twocontract[i].vchRUserUpdate = userUpdate;
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        twocontract[i].biTApproverChief = true;
        twocontract[i].biTApproverSectionManager = true;
        twocontract[i].biTApproverDirector = true;
        // cập nhật lại các lý do từ chối
        twocontract[i].nvchRApproverChief = '';
        twocontract[i].nvchRApproverManager = '';
        twocontract[i].nvchRApproverDirector = '';
        twocontract[i].biTApproverChief = true;
        twocontract[i].biTApproverSectionManager = true;
        twocontract[i].biTApproverDirector = true;

        switch (twocontract[i].inTStatusId) {
          case 3:
            twocontract[i].inTStatusId = 4;
            twocontract[i].nvchRPthcSection = userUpdate;
            twocontract[i].vchRLeaderEvalution = userApprover;
          case 4:
            if (twocontract[i].nvchROther != 'OK' &&
                (twocontract[i].vchRNote == null ||
                    twocontract[i].vchRNote == "")) {
              throw Exception(
                '${tr('InputError1')} ${twocontract[i].vchREmployeeId}',
              );
            }
            if (twocontract[i].vchRReasultsLeader != 'OK' &&
                (twocontract[i].nvchRCompleteWork == 'OK' &&
                    twocontract[i].nvchRUseful == 'OK' &&
                    twocontract[i].nvchROther == 'OK')) {
              throw Exception(
                '${tr('InputError1')} ${twocontract[i].vchREmployeeId}',
              );
            }
            if (twocontract[i].biTNoReEmployment == false &&
                (twocontract[i].nvchRNoReEmpoyment == null ||
                    twocontract[i].nvchRNoReEmpoyment == "")) {
              throw Exception(
                '${tr('InputError')} ${twocontract[i].vchREmployeeId}',
              );
            }
            twocontract[i].inTStatusId = 6;
            twocontract[i].vchRLeaderEvalution = userUpdate;
            twocontract[i].useRApproverChief = userApprover;
            twocontract[i].dtMLeadaerEvalution = formatDateTime(DateTime.now());
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
      showError('Failed to update two contract: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  //update thong tin Phe duyet
  Future<void> updateListTwoContractApproval(String userApprover) async {
    try {
      // List<TwoContract> twocontract,
      //fetchPTHCData();
      final twocontract = getSelectedItems();
      List<dynamic> notApproval = [];
      String mailSend = "";
      String sectionAp = "";
      if (twocontract.isEmpty) {
        throw Exception(tr('LoiGui'));
      }
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
            twocontract[i].dtMApproverChief = formatDateTime(DateTime.now());
            twocontract[i].useRApproverChief = userApprover;
            if (twocontract[i].biTApproverChief == true ||
                twocontract[i].biTApproverChief) {
              twocontract[i].inTStatusId = 7;
              mailSend = await NextApprovel(
                section: twocontract[i].vchRCodeSection,
                chucVu: "Dept Manager",
                dept: dept,
              );
            } else {
              if ((twocontract[i].nvchRApproverChief?.isEmpty ?? true)) {
                throw Exception(
                  '${tr('NotApproval')} ${twocontract[i].vchREmployeeName}',
                );
              }
              final json = twocontract[i].toJson();
              final contractCopy = TwoContract.fromJson(json);
              notApproval.add(contractCopy);
              twocontract[i].inTStatusId = 4;
            }
          case 7:
            twocontract[i].dtMApproverManager = formatDateTime(DateTime.now());
            twocontract[i].useRApproverSectionManager = userApprover;
            if (twocontract[i].biTApproverSectionManager == true) {
              twocontract[i].inTStatusId = 8;
              mailSend = await NextApprovel(
                section: twocontract[i].vchRCodeSection,
                chucVu: "Director",
                dept: dept,
              );
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
          case 8:
            twocontract[i].dtMApproverDirector = formatDateTime(DateTime.now());
            twocontract[i].useRApproverDirector = userApprover;

            //xu ly khi xong
            mailSend = "k";
            //
            if (twocontract[i].biTApproverDirector == true) {
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
            }
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
          // controlleruser.SendMail(
          //   '2',
          //   mailSend,
          //   mailSend,
          //   mailSend,
          // );
          // k mo vi mo se gui cho quan ly cac phong
          controlleruser.SendMail(
            '2',
            "vietdo@brothergroup.net,vanug@brothergroup.net,tuanho@brothergroup.net,huyenvg@brothergroup.net, hoaiph@brothergroup.net",
            "nguyenduy.khanh@brother-bivn.com.vn;hoangviet.dung@brother-bivn.com.vn",
            "vuduc.hai@brother-bivn.com.vn",
          );
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
      final response = await http.delete( // Thường xóa nhiều item dùng POST hoặc DELETE với body
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
  // xuat file
  Future<void> exportToExcelTwoContract() async {
    try {
      isLoadingExport(true);
      final response = await http.get(
        Uri.parse('${Common.API}${Common.TwoGetAll}'),
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
          ..useRApproverDirector;
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
        if (parsedEndDate != null && parsedEndDate.difference(DateTime.now()).inDays.abs() <= 50) {
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
          ..useRApproverDirector;
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
        if (
            parsedEndDate != null && parsedEndDate.difference(DateTime.now()).inDays.abs() <= 50) {
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
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      if (!status.contains('OK')) {
        dataList[index].vchRReasultsLeader = 'NG';
        filterdataList[index].vchRReasultsLeader = 'NG';
      } else if (dataList[index].nvchRCompleteWork == 'OK' &&
          dataList[index].nvchRUseful == 'OK') {
        dataList[index].vchRReasultsLeader = 'OK';
        filterdataList[index].vchRReasultsLeader = 'OK';
      }
      dataList[index].nvchROther = status;
      filterdataList[index].nvchROther = status;
      if (status == 'OK') {
        dataList[index].vchRNote = '';
        filterdataList[index].vchRNote = '';
      }
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  // ghi chu
  void updateNote(String employeeCode, String status) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].vchRNote = status;
      filterdataList[index].vchRNote = status;
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  void updateEvaluationStatus(String employeeCode, String status) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].vchRReasultsLeader = status;
      filterdataList[index].vchRReasultsLeader = status;
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  void updateRehireStatus(String employeeCode, bool value) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].biTNoReEmployment = value;
      filterdataList[index].biTNoReEmployment = value;
      if (value == true) {
        dataList[index].nvchRNoReEmpoyment = '';
        filterdataList[index].nvchRNoReEmpoyment = '';
      }
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  void updateNotRehireReason(String employeeCode, String reason) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].nvchRNoReEmpoyment = reason;
      filterdataList[index].nvchRNoReEmpoyment = reason;
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  void updateCongViec(String employeeCode, String reason) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      if (!reason.contains('OK')) {
        dataList[index].vchRReasultsLeader = 'NG';
        filterdataList[index].vchRReasultsLeader = 'NG';
      } else if (dataList[index].nvchROther == 'OK' &&
          dataList[index].nvchRUseful == 'OK') {
        dataList[index].vchRReasultsLeader = 'OK';
        filterdataList[index].vchRReasultsLeader = 'OK';
      }
      dataList[index].nvchRCompleteWork = reason;
      filterdataList[index].nvchRCompleteWork = reason;
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  void updateUserFull(String employeeCode, String reason) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      if (!reason.contains('OK')) {
        dataList[index].vchRReasultsLeader = 'NG';
        filterdataList[index].vchRReasultsLeader = 'NG';
      } else if (dataList[index].nvchRCompleteWork == 'OK' &&
          dataList[index].nvchROther == 'OK') {
        dataList[index].vchRReasultsLeader = 'OK';
        filterdataList[index].vchRReasultsLeader = 'OK';
      }
      dataList[index].nvchRUseful = reason;
      filterdataList[index].nvchRUseful = reason;
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  // Các thông tin lưu ở Phê duyệt
  void updateNotRehireReasonApprovel(
    String employeeCode,
    String reason,
    int? statusId,
  ) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      switch (statusId) {
        case 6:
          dataList[index].nvchRApproverChief = reason;
          filterdataList[index].nvchRApproverChief = reason;
        case 7:
          dataList[index].nvchRApproverManager = reason;
          filterdataList[index].nvchRApproverManager = reason;
        case 8:
          dataList[index].nvchRApproverDirector = reason;
          filterdataList[index].nvchRApproverDirector = reason;
      }
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  void updateRehireStatusApprovel(
    String employeeCode,
    bool value,
    int? statusId,
  ) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      switch (statusId) {
        case 6:
          dataList[index].biTApproverChief = value;
          filterdataList[index].biTApproverChief = value;
        case 7:
          dataList[index].biTApproverSectionManager = value;
          filterdataList[index].biTApproverSectionManager = value;
        case 8:
          dataList[index].biTApproverDirector = value;
          filterdataList[index].biTApproverDirector = value;
      }
      dataList.refresh();
      filterdataList.refresh();
    }
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
      isLoading(true);
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
            twocontract[i].dtMApproverChief = formatDateTime(DateTime.now());
            twocontract[i].useRApproverChief = userApprover;
            twocontract[i].nvchRApproverChief = reson;
            twocontract[i].biTApproverChief = false;
            final json = twocontract[i].toJson();
            final contractCopy = TwoContract.fromJson(json);
            notApproval.add(contractCopy);
            twocontract[i].inTStatusId = 4;
          case 7:
            twocontract[i].dtMApproverManager = formatDateTime(DateTime.now());
            twocontract[i].useRApproverSectionManager = userApprover;
            twocontract[i].nvchRApproverManager = reson;
            twocontract[i].biTApproverSectionManager = false;
            final json = twocontract[i].toJson();
            final contractCopy = TwoContract.fromJson(json);
            notApproval.add(contractCopy);
            twocontract[i].inTStatusId = 4;
          case 8:
            twocontract[i].dtMApproverDirector = formatDateTime(DateTime.now());
            twocontract[i].useRApproverDirector = userApprover;
            twocontract[i].nvchRApproverDirector = reson;
            twocontract[i].biTApproverDirector = false;
            final json = twocontract[i].toJson();
            final contractCopy = TwoContract.fromJson(json);
            notApproval.add(contractCopy);
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
