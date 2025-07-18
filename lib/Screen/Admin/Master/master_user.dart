import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/User.dart';

class MasterUser extends StatefulWidget {
  const MasterUser({super.key});

  @override
  State<MasterUser> createState() => _MasterUserState();
}

class _MasterUserState extends State<MasterUser> {
  final DashboardControllerUser controller = Get.put(DashboardControllerUser());
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            _buildHeader(),
            const SizedBox(height: 16),

            // Search and Action Buttons
            _buildSearchAndActions(),
            const SizedBox(height: 16),

            // Data Table
            Expanded(
              child: Obx(() {
                Visibility(
                  visible: false,
                  child: Text(controller.filteredUserList.length.toString()),
                );
                return _buildDataTable();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Master Quản Lý Thông Tin User',
          style: TextStyle(
            color: Common.primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quản lý thông tin người dùng hệ thống',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSearchAndActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchTextController,
              onChanged: (value) {
                controller.searchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã, tên nhân viên...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                suffixIcon: controller.searchTextController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          controller.searchTextController.clear();
                          controller.searchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Action Buttons
        _buildActionButton(
          icon: Iconsax.import,
          color: Colors.blue,
          tooltip: 'Import dữ liệu',
          onPressed: () => _showImportDialog(),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.export,
          color: Colors.green,
          tooltip: 'Export dữ liệu',
          onPressed: () => _showExportDialog(),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.add,
          color: Colors.orange,
          tooltip: 'Thêm mới',
          onPressed: () => _showAddDialog(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDataTable() {
    double width = MediaQuery.of(context).size.width;
    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: const CardThemeData(color: Colors.white, elevation: 0),
        dividerTheme: DividerThemeData(
          color: Colors.grey[200],
          thickness: 1,
          space: 0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width - 34,
              child: PaginatedDataTable2(
                columnSpacing: 12,
                minWidth: 1000,
                horizontalMargin: 12,
                dataRowHeight: 56,
                headingRowHeight: 56,
                headingTextStyle: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
                headingRowDecoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.blue[50],
                ),
                showCheckboxColumn: true,
                showFirstLastButtons: true,
                renderEmptyRowsInTheEnd: false,
                rowsPerPage: 10,
                availableRowsPerPage: const [5, 10, 20, 50],
                onRowsPerPageChanged: (value) {},
                sortColumnIndex: controller.sortColumnIndex.value,

                ///
                sortAscending: controller.sortAscending.value,
                sortArrowBuilder: (ascending, sorted) {
                  return Icon(
                    sorted
                        ? ascending
                              ? Iconsax.arrow_up_2
                              : Iconsax.arrow_down_1
                        : Iconsax.row_horizontal,
                    size: 16,
                    color: sorted ? Colors.blue[800] : Colors.grey,
                  );
                },
                columns: [
                  DataColumn2(
                    label: const Text('Phòng ban'),
                    fixedWidth: 150,
                    onSort: controller.sortById,
                  ),
                  DataColumn2(
                    label: const Text('Mã nhân viên'),
                    // fixedWidth: 150,
                  ),
                  DataColumn2(
                    label: const Text('Tên nhân viên'),
                    // fixedWidth: 200,
                  ),
                  DataColumn2(
                    label: const Text('ADID'),
                    // fixedWidth: 150,
                  ),
                  DataColumn2(
                    label: const Text('Nhóm quyền'),
                    // fixedWidth: 150,
                  ),
                  const DataColumn2(label: Text('Trạng thái'), fixedWidth: 120),
                  const DataColumn2(label: Text('Hành động'), fixedWidth: 180),
                ],
                source: MyData(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Import Dữ Liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn file Excel để import dữ liệu',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.document_upload),
              label: const Text('Chọn File'),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              // Import logic
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Export Dữ Liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn định dạng export',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildExportOption(Iconsax.document_text, 'Excel'),
                _buildExportOption(Iconsax.document2, 'PDF'),
                _buildExportOption(Iconsax.document_text, 'CSV'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              // Export logic
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  void _showAddDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Thêm User Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Mã nhân viên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Tên nhân viên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: 'Phòng ban',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['RD', 'HR', 'Finance', 'Marketing']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              // Add logic
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

class MyData extends DataTableSource {
  final DashboardControllerUser controller = Get.find();

  @override
  DataRow? getRow(int index) {
    final data = controller.filteredUserList[index];
    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (index.isEven) {
          return Colors.grey[50];
        }
        return null;
      }),
      onTap: () {}, //=> _showDetailDialog(data),
      selected: controller.selectRows[index],
      onSelectChanged: (value) {
        controller.selectRows[index] = value ?? false;
        controller.selectRows.refresh();
        notifyListeners();
      },
      cells: [
        DataCell(
          Text(data.chR_SEC_CODE, style: TextStyle(color: Colors.blue[800])),
        ),
        DataCell(Text(data.chR_EMPLOYEE_ID)),
        DataCell(Text(data.nvchR_NAME_ID)),
        DataCell(Text(data.chR_USERID)),
        DataCell(Text(data.chR_GROUP)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: data.inT_LOCK == 0 ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: data.inT_LOCK == 0 ? Colors.green[100]! : Colors.red[100]! ),
            ),
            child: 
            Text(data.inT_LOCK == 0 ? 'Active' :'Delete', style: TextStyle(color: data.inT_LOCK == 0 ? Colors.green[800] : Colors.red[800] )),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Iconsax.edit_2,
                color: Colors.blue,
                onPressed: () {}, // => _handleEdit(data),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Iconsax.trash,
                color: Colors.red,
                onPressed: () {}, //=> _handleDelete(data),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Iconsax.eye,
                color: Colors.green,
                onPressed: () {}, //=> _showDetailDialog(data),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  void _showDetailDialog(Map<String, String> data) {
    Get.dialog(
      AlertDialog(
        title: Text('Chi tiết: ${data['Column3']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Phòng ban:', data['Column1'] ?? ""),
              _buildDetailRow('Mã nhân viên:', data['Column2'] ?? ""),
              _buildDetailRow('Tên nhân viên:', data['Column3'] ?? ""),
              _buildDetailRow('ADID:', data['Column4'] ?? ""),
              _buildDetailRow('Nhóm quyền:', data['Column5'] ?? ""),
              const SizedBox(height: 16),
              const Text(
                'Lịch sử hoạt động:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                3,
                (index) => _buildActivityItem('Hoạt động ${index + 1}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _handleEdit(Map<String, String> data) {
    Get.dialog(
      AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Tên nhân viên',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: data['Column3']),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: 'Nhóm quyền',
                border: OutlineInputBorder(),
              ),
              value: data['Column5'],
              items: [
                'QL',
                'NV',
                'Admin',
                'Guest',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              // Save logic
              Get.back();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _handleDelete(Map<String, String> data) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn chắc chắn muốn xóa ${data['Column3']}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              controller.deleteUser(1); // truyen id
              Get.back();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => controller.filteredUserList.length;

  @override
  int get selectedRowCount => 0;
}

class DashboardControllerUser extends GetxController {
  var userList = <User>[].obs;
  var filteredUserList = <User>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortColumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse(Common.API + Common.UserGetAll),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          userList.assignAll(data.map((user) => User.fromJson(user)).toList());
          filteredUserList.assignAll(userList);
          selectRows.assignAll(
            List.generate(userList.length, (index) => false),
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

  void sortById(int columnIndex, bool ascending) {
    sortAscending.value = ascending;
    sortColumnIndex.value = columnIndex;

    filteredUserList.sort((a, b) {
      switch (columnIndex) {
        case 0: // ID
          return ascending ? a.id.compareTo(b.id) : b.id.compareTo(a.id);
        case 1: // User ID
          return ascending
              ? a.chR_USERID.compareTo(b.chR_USERID)
              : b.chR_USERID.compareTo(a.chR_USERID);
        case 2: // Name
          return ascending
              ? a.nvchR_NAME_ID.compareTo(b.nvchR_NAME_ID)
              : b.nvchR_NAME_ID.compareTo(a.nvchR_NAME_ID);
        default:
          return 0;
      }
    });
  }

  void searchQuery(String query) {
    if (query.isEmpty) {
      filteredUserList.assignAll(userList);
    } else {
      filteredUserList.assignAll(
        userList.where(
          (user) =>
              user.chR_USERID.toLowerCase().contains(query.toLowerCase()) ||
              user.nvchR_NAME_ID.toLowerCase().contains(query.toLowerCase()) ||
              user.chR_EMPLOYEE_ID.toLowerCase().contains(query.toLowerCase()),
        ),
      );
    }
  }

  void deleteUser(int id) {
    userList.removeWhere((user) => user.id == id);
    filteredUserList.removeWhere((user) => user.id == id);
    selectRows.removeAt(userList.indexWhere((user) => user.id == id));
  }
}
