import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/User.dart';

class MasterUserTem extends StatefulWidget {
  const MasterUserTem({super.key});

  @override
  State<MasterUserTem> createState() => _MasterUserTemState();
}

class _MasterUserTemState extends State<MasterUserTem> {
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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            _buildSearchAndActions(),
            const SizedBox(height: 16),
            Expanded(child: _buildDataTable()),
            _buildPaginationControls(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Common.primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
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
                // controller.searchQuery(value);
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
                          // controller.searchTextController.clear();
                          // controller.searchQuery('');
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
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.export,
          color: Colors.green,
          tooltip: 'Export dữ liệu',
          onPressed: (){},
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

  Widget _buildFilterSection() {
    return Obx(
      () => Row(
        children: [
          _buildDropdown(
            value: controller.selectedDepartment.value,
            items: controller.departments,
            hint: 'Phòng ban',
            onChanged: (value) {
              controller.selectedDepartment.value = value!;
              controller.fetchUserData();
            },
          ),
          const SizedBox(width: 12),
          _buildDropdown(
            value: controller.selectedStatus.value,
            items: ['All', 'Active', 'Locked'],
            hint: 'Trạng thái',
            onChanged: (value) {
              controller.selectedStatus.value = value!;
              controller.fetchUserData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Expanded(
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          items: items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng số: ${controller.totalRecords.value} bản ghi',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Row(
              children: [
                DropdownButton<int>(
                  value: controller.recordsPerPage.value,
                  items: [5, 10, 20, 50].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value dòng/trang'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    controller.recordsPerPage.value = value!;
                    controller.currentPage.value = 1;
                    controller.fetchUserData();
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Iconsax.arrow_left_2),
                  onPressed: controller.currentPage.value > 1
                      ? () {
                          controller.currentPage.value--;
                          controller.fetchUserData();
                        }
                      : null,
                ),
                Text('Trang ${controller.currentPage.value}'),
                IconButton(
                  icon: const Icon(Iconsax.arrow_right_3),
                  onPressed:
                      controller.currentPage.value <
                          (controller.totalRecords.value /
                                  controller.recordsPerPage.value)
                              .ceil()
                      ? () {
                          controller.currentPage.value++;
                          controller.fetchUserData();
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
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
  return Obx(() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

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
              width: MediaQuery.of(context).size.width - 34,
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
                rowsPerPage: controller.recordsPerPage.value,
                availableRowsPerPage: const [5, 10, 20, 50],
                onRowsPerPageChanged: (value) {
                  controller.recordsPerPage.value = value!;
                  controller.fetchUserData();
                },
                sortColumnIndex: controller.sortColumnIndex.value,
                sortAscending: controller.sortAscending.value,
                columns: [
                  DataColumn2(
                    label: const Text('Phòng ban'),
                    fixedWidth: 150,

                  ),
                  DataColumn2(
                    label: const Text('Mã nhân viên'),
                  ),
                  DataColumn2(
                    label: const Text('Tên nhân viên'),

                  ),
                  DataColumn2(
                    label: const Text('ADID'),

                  ),
                  DataColumn2(
                    label: const Text('Nhóm quyền'),
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
  });
}
  void _showAddDialog() {
  final newUser = User(
    id: 0,
  );

  Get.dialog(
    AlertDialog(
      title: const Text('Thêm User Mới'),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Mã nhân viên',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => newUser.chREmployeeId = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Tên nhân viên',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => newUser.nvchRNameId = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'ADID',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => newUser.chRUserid = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Nhóm quyền',
                  border: OutlineInputBorder(),
                ),
                items: ['Admin', 'QL', 'NV', 'Guest']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => newUser.chRGroup = value ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Hủy'),
        ),
        Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      controller.addUser(newUser);
                      Get.back();
                    },
              child: const Text('Thêm'),
            )),
      ],
    ),
  );
}

void _showEditDialog(User user) {
  final editedUser = User.fromJson(user.toJson());

  Get.dialog(
    AlertDialog(
      title: Text('Chỉnh sửa ${user.nvchRNameId}'),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: user.chREmployeeId,
                decoration: InputDecoration(
                  labelText: 'Mã nhân viên',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => editedUser.chREmployeeId = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: user.nvchRNameId,
                decoration: InputDecoration(
                  labelText: 'Tên nhân viên',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => editedUser.nvchRNameId= value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: user.inTLock,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 0, child: Text('Active')),
                  DropdownMenuItem(value: 1, child: Text('Locked')),
                ],
                onChanged: (value) => editedUser.inTLock = value ?? 0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Hủy'),
        ),
        Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      controller.updateUser(editedUser);
                      Get.back();
                    },
              child: const Text('Lưu'),
            )),
      ],
    ),
  );
}

void _showDeleteDialog(int id) {
  Get.dialog(
    AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: const Text('Bạn có chắc chắn muốn xóa user này?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            controller.deleteUser(id);
            Get.back();
          },
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
}

class MyData extends DataTableSource {
  final DashboardControllerUser controller = Get.find();

  @override
  DataRow getRow(int index) {
    final data = controller.filteredUserList[index];
    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>((states) {
        if (index.isEven) return Colors.grey[50];
        return null;
      }),
      selected: controller.selectRows[index],
      onSelectChanged: (value) {
        controller.selectRows[index] = value ?? false;
        notifyListeners();
      },
      cells: [
        DataCell(Text(data.chRSecCode?? '')),
        DataCell(Text(data.chREmployeeId?? '')),
        DataCell(Text(data.nvchRNameId?? '')),
        DataCell(Text(data.chRUserid?? '')),
        DataCell(Text(data.chRGroup?? '')),
        DataCell(_buildStatusBadge(data.inTLock?? 0)),
        DataCell(_buildActionButtons(data)),
      ],
    );
  }

  Widget _buildStatusBadge(int lockStatus) {
    final isActive = lockStatus == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[100]! : Colors.red[100]!,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Locked',
        style: TextStyle(
          color: isActive ? Colors.green[800] : Colors.red[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(User user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Iconsax.edit_2, size: 18, color: Colors.blue),
          onPressed: () => _showEditDialog(user),
          tooltip: 'Chỉnh sửa',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Iconsax.trash, size: 18, color: Colors.red),
          onPressed: () => _showDeleteDialog(user.id ?? 0),
          tooltip: 'Xóa',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Iconsax.eye, size: 18, color: Colors.green),
          onPressed: () => _showDetailDialog(user),
          tooltip: 'Xem chi tiết',
        ),
      ],
    );
  }

  void _showEditDialog(User user) {
    final context = Get.context!;
    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(user: user),
    );
  }

  void _showDeleteDialog(int id) {
    final context = Get.context!;
    showDialog(
      context: context,
      builder: (context) => _DeleteUserDialog(id: id),
    );
  }

  void _showDetailDialog(User user) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  )),
              ),
              const SizedBox(height: 16),
              Text(
                'Chi tiết người dùng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800]),
                ),
              const Divider(),
              _buildDetailItem('Mã nhân viên:', user.chREmployeeId?? ''),
              _buildDetailItem('Tên nhân viên:', user.nvchRNameId?? ''),
              _buildDetailItem('ADID:', user.chRUserid?? ''),
              _buildDetailItem('Nhóm quyền:', user.chRGroup?? ''),
              _buildDetailItem('Phòng ban:', user.chRSecCode?? ''),
              _buildDetailItem('Trạng thái:',
                  user.inTLock == 0 ? 'Active' : 'Locked'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
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

  // Thêm các biến mới
  var totalRecords = 0.obs;
  var currentPage = 1.obs;
  var recordsPerPage = 10.obs;
  var selectedDepartment = 'All'.obs;
  var selectedStatus = 'All'.obs;
  var departments = <String>[].obs;
  var isLoadingExport = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
    fetchDepartments();
    fetchTotalRecords();
  }

  Future<void> fetchUserData() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse(
          '${Common.API}${Common.UserGetAll}?page=${currentPage.value}&limit=${recordsPerPage.value}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          userList.assignAll(data.map((user) => User.fromJson(user)).toList());
          filteredUserList.assignAll(userList);
          updateSelectRows();
        }
      }
    } catch (e) {
      showError('Failed to load users: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTotalRecords() async {
    try {
      final response = await http.get(
        Uri.parse('${Common.API}${Common.GetUserCount}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        totalRecords.value = jsonData['data'] ?? 0;
      }
    } catch (e) {
      showError('Failed to get total records: $e');
    }
  }

  Future<void> fetchDepartments() async {
    // Giả lập lấy danh sách phòng ban
    departments.value = ['All', 'RD', 'HR', 'Finance', 'Marketing', 'IT'];
  }

  Future<void> exportToExcel() async {
    try {
      isLoadingExport(true);
      final response = await http.get(
        Uri.parse('${Common.API}${Common.UserGetAll}?export=excel'),
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
    } finally {
      isLoadingExport(false);
    }
  }

  Future<void> addUser(User newUser) async {
    try {
      isLoading(true);
      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddUser}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newUser.toJson()),
      );

      if (response.statusCode == 200) {
        fetchUserData();
        Get.snackbar(
          'Success',
          'User added successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      showError('Failed to add user: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      isLoading(true);
      final response = await http.put(
        Uri.parse('${Common.API}${Common.UpdateUser}${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        fetchUserData();
        Get.snackbar(
          'Success',
          'User updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      showError('Failed to update user: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteUser(int id, {bool logical = true}) async {
    try {
      isLoading(true);
      final endpoint = logical ? Common.DeleteIDLogic : Common.DeleteID;
      final response = await http.delete(
        Uri.parse('${Common.API}$endpoint$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        fetchUserData();
        Get.snackbar(
          'Success',
          'User deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      showError('Failed to delete user: $e');
    } finally {
      isLoading(false);
    }
  }

  void updateSelectRows() {
    selectRows.assignAll(List.generate(userList.length, (index) => false));
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
}
class _EditUserDialog extends StatelessWidget {
  final User user;
  final DashboardControllerUser controller = Get.find();

  _EditUserDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    final editedUser = User.fromJson(user.toJson());

    return AlertDialog(
      title: Text('Chỉnh sửa ${user.nvchRNameId}'),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: user.chREmployeeId,
                decoration: const InputDecoration(
                  labelText: 'Mã nhân viên',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => editedUser.chREmployeeId = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: user.nvchRNameId,
                decoration: const InputDecoration(
                  labelText: 'Tên nhân viên',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => editedUser.nvchRNameId = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: user.inTLock,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Active')),
                  DropdownMenuItem(value: 1, child: Text('Locked')),
                ],
                onChanged: (value) => editedUser.inTLock = value ?? 0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Hủy'),
        ),
        Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      controller.updateUser(editedUser);
                      Get.back();
                    },
              child: const Text('Lưu'),
            )),
      ],
    );
  }
}

class _DeleteUserDialog extends StatelessWidget {
  final int id;
  final DashboardControllerUser controller = Get.find();

  _DeleteUserDialog({required this.id});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: const Text('Bạn có chắc chắn muốn xóa user này?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Hủy'),
        ),
        Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      controller.deleteUser(id);
                      Get.back();
                    },
              child: const Text('Xóa'),
            )),
      ],
    );
  }
}



// void _showImportDialog() {
//   final controller = Get.find<DashboardControllerApprentice>();

//   Get.dialog(
//     AlertDialog(
//       title: const Text('Import Dữ Liệu'),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Chọn file Excel để import dữ liệu',
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 20),
//             Obx(() => ElevatedButton.icon(
//                   icon: controller.isLoading.value
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Icon(Iconsax.document_upload),
//                   label: controller.isLoading.value
//                       ? const Text('Đang xử lý...')
//                       : const Text('Chọn File'),
//                   onPressed: controller.isLoading.value
//                       ? null
//                       : () async {
//                           try {
//                             FilePickerResult? result =
//                                 await FilePicker.platform.pickFiles(
//                               type: FileType.custom,
//                               allowedExtensions: ['xlsx'],
//                               allowMultiple: false,
//                             );

//                             if (result != null && result.files.isNotEmpty) {
//                               controller.isLoading.value = true;

//                               // Đọc file Excel
//                               final file = File(result.files.first.path!);
//                               final bytes = await file.readAsBytes();
//                               final excel = Excel.decodeBytes(bytes);

//                               if (excel.tables.isEmpty) {
//                                 throw Exception('File Excel không có dữ liệu');
//                               }

//                               // Lấy sheet đầu tiên
//                               final sheet = excel.tables.values.first;

//                               // Chuẩn bị danh sách dữ liệu mới
//                               List<Map<String, String>> newData = [];

//                               // Bắt đầu từ hàng thứ 2 (bỏ qua header)
//                               for (var i = 1; i < sheet!.rows.length; i++) {
//                                 final row = sheet.rows[i];
//                                 if (row.isEmpty) continue;

//                                 newData.add({
//                                   'employeeCode':
//                                       _getCellValue(row[1]) ?? 'NV${1000 + i}',
//                                   'gender': _getCellValue(row[2]) ?? '',
//                                   'fullName': _getCellValue(row[3]) ??
//                                       'Nguyễn Văn ${String.fromCharCode(65 + i % 26)}',
//                                   'department': _getCellValue(row[4]) ?? '',
//                                   'group': _getCellValue(row[5]) ?? '',
//                                   'age': _getCellValue(row[6]) ?? '',
//                                   'position': _getCellValue(row[7]) ?? '',
//                                   'salaryGrade': _getCellValue(row[8]) ?? '',
//                                   'contractValidity': _getCellValue(row[9]) ??
//                                       'Còn hiệu lực',
//                                   'contractEndDate': _getCellValue(row[10]) ??
//                                       '${DateTime.now().add(Duration(days: 365)).toString().substring(0, 10)}',
//                                   'earlyLeaveCount': _getCellValue(row[11]) ??
//                                       '0',
//                                   'paidLeaveDays': _getCellValue(row[12]) ??
//                                       '0',
//                                   'unpaidLeaveDays': _getCellValue(row[13]) ??
//                                       '0',
//                                   'unreportedLeaveDays':
//                                       _getCellValue(row[14]) ?? '0',
//                                   'violationCount': _getCellValue(row[15]) ??
//                                       '0',
//                                   'healthStatus': _getCellValue(row[16]) ??
//                                       'Đạt',
//                                   'evaluationStatus': _getCellValue(row[17]) ??
//                                       'OK',
//                                   'notRehire': _getCellValue(row[18]) ?? 'NG',
//                                   'notRehireReason': _getCellValue(row[19]) ??
//                                       '',
//                                   'reason': '',
//                                 });
//                               }

//                               if (newData.isNotEmpty) {
//                                 controller.dataList.assignAll(newData);
//                                 controller.filterdataList.assignAll(newData);
//                                 controller.selectRows.assignAll(
//                                     List.generate(newData.length, (index) => false));

//                                 Get.back();
//                                 Get.snackbar(
//                                   'Thành công',
//                                   'Đã import ${newData.length} bản ghi',
//                                   backgroundColor: Colors.green,
//                                   colorText: Colors.white,
//                                   duration: const Duration(seconds: 3),
//                                 );
//                               } else {
//                                 throw Exception('Không có dữ liệu hợp lệ để import');
//                               }
//                             }
//                           } catch (e) {
//                             Get.snackbar(
//                               'Lỗi',
//                               'Import thất bại: ${e.toString()}',
//                               backgroundColor: Colors.red,
//                               colorText: Colors.white,
//                               duration: const Duration(seconds: 3),
//                             );
//                           } finally {
//                             controller.isLoading.value = false;
//                           }
//                         },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 )),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: controller.isLoading.value ? null : () => Get.back(),
//           child: const Text('Hủy'),
//         ),
//       ],
//     ),
//   );
// }

// String? _getCellValue(CellValue? cell) {
//   if (cell == null) return null;
//   return cell.value.toString();
// }