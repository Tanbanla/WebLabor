import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/Apprentice_Contract.dart';
import 'package:web_labor_contract/class/Two_Contract.dart';
import 'package:intl/intl.dart';


class DashboardControllerApporver extends GetxController {
  final RxList<dynamic> dataList = <dynamic>[].obs;
  final RxList<dynamic> filterdataList = <dynamic>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;
  final RxString currentContractType = ''.obs;

  @override
  void onInit() {
    super.onInit();
    //fetchDummyData();
  }
  List<dynamic> getSelectedItems() {
    List<dynamic> selectedItems = [];
    for (int i = 0; i < selectRows.length; i++) {
      if (selectRows[i]) {
        selectedItems.add(filterdataList[i]);
      }
    }
    return selectedItems;
  }
Future<void> updateListContractApproval(
    String userApprover,
    String userUpdate,
    String? contractType,
  ) async {
    try {
      // List<TwoContract> twocontract,
      final twocontract = getSelectedItems();
      if (twocontract.isEmpty) {
        throw Exception('Lỗi danh sách gửi đi không có dữ liệu!');
      }
      isLoading(true);
      for (int i = 0; i < twocontract.length; i++) {
        twocontract[i].vchRUserUpdate = userUpdate;
        twocontract[i].dtMUpdate = formatDateTime(DateTime.now());
        if(twocontract[i].biTApproverPer){
          twocontract[i].inTStatusId = 3;
        }else{
          twocontract[i].inTStatusId = 1;
        }
        twocontract[i].dtMApproverPer = formatDateTime(DateTime.now());
        twocontract[i].useRApproverPer = userApprover;
      }
      // Determine API endpoint and column mapping based on contract type
      final apiEndpoint = contractType == 'two' 
          ? Common.UpdataListTwo
          : Common.UpdataListApprentice;
      final response = await http.put(
        Uri.parse('${Common.API}$apiEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(twocontract),
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
                  false) || (item.vchRCodeApprover?.toLowerCase().contains(query.toLowerCase(),) ?? false),
        ),
      );
    }
  }

    Future<void> fetchData({
    String? contractType,
    String? statusId,
    String? section,
    String? adid,
  }) async {
    try {
      if (statusId == null || statusId.isEmpty) {
        throw Exception('Status ID is required');
      }

      isLoading(true);
      currentContractType.value = contractType.toString();

      // Determine API endpoint and column mapping based on contract type
      final apiEndpoint = contractType == 'two' 
          ? Common.TwoSreachBy
          : Common.ApprenticeSreachBy;

      final columnMapping = _getColumnMapping(statusId);

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
          {
            "field": columnMapping,
            "value": adid,
            "operator": "=",
            "logicType": "AND"
          },
      ];

      final requestBody = {
        "pageNumber": -1,
        "pageSize": 10,
        "filters": filters,
      };

      final response = await http.post(
        Uri.parse(Common.API + apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data']['data'] ?? [];

          // Use the appropriate model based on contract type
          dataList.assignAll(data.map((contract) => contractType == 'two'
              ? TwoContract.fromJson(contract)
              : ApprenticeContract.fromJson(contract)));

          filterdataList.assignAll(dataList);
          selectRows.assignAll(List.generate(dataList.length, (index) => false));
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('Failed to load contract data');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading(false);
    }
  }

  String _getColumnMapping(String statusId) {
    switch (statusId) {
      case "2":
        return "USER_APPROVER_PER";
      case "3":
        return "VCHR_PTHC_SECTION";
      case "4":
        return "VCHR_LEADER_EVALUTION";
      case "5":
        return "USER_APPROVER_CHIEF";
      case "6":
        return "USER_APPROVER_SECTION_MANAGER";
      case "7":
        return "USER_APPROVER_DIRECTOR";
      default:
        return "";
    }
  }

  // Helper method to check current contract type
  bool isTwoContract() => currentContractType.value == 'two';
  bool isApprenticeContract() => currentContractType.value == 'apprentice';
  // điền đánh giá
  void updateApproval(String employeeCode, bool status) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].biTApproverPer = status;
      filterdataList[index].biTApproverPer= status;
      dataList.refresh();
      filterdataList.refresh();
    }
  }

  void updateNoteApprovel(String employeeCode, String status) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].nvchRApproverPer = status;
      filterdataList[index].nvchRApproverPer = status;
      dataList.refresh();
      filterdataList.refresh();
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
