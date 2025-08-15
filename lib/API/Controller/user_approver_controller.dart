import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/User_Approver.dart';

class DashboardControllerUserApprover extends GetxController {
  var dataList = <ApproverUser>[].obs;
  var filterdataList = <ApproverUser>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  var isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    //fetchDummyData();
  }
  Future<void> changeStatus(
    String newSection,
    String newChuVu,
  ) async {
    await fetchDummyData(section: newSection, chucVu: newChuVu);
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

  // lay du lieu
  Future<void> fetchDummyData({
    String? section,
    String? chucVu,
  }) async {
    try {
      isLoading(true);
      final Uri uri = Uri.parse('${Common.API}${Common.UserApprover}').replace(
        queryParameters: {
          'section': section,
          'positionGroups': chucVu,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          dataList.assignAll(
            data
                .map((twocontract) => ApproverUser.fromJson(twocontract))
                .where((users) => users.chREmployeeAdid != null && users.chREmployeeAdid !='')
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
}
