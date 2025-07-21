import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/Common/common.dart';

class MasterPTHC extends StatefulWidget {
  const MasterPTHC({super.key});

  @override
  State<MasterPTHC> createState() => _MasterPTHCState();
}

class _MasterPTHCState extends State<MasterPTHC> {
  final DashboardControllerPTHC controller = Get.put(DashboardControllerPTHC());
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Common.primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
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
            Expanded(child: Obx(() => _buildDataTable())),
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
          'Master Quản Lý PTHC',
          style: TextStyle(
            color: Common.primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quản lý thông tin phê duyệt và thông báo',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSearchAndActions() {
    return Row(
      children: [
        // Search Field
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
              onChanged: (value) => controller.searchQuery(value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo phòng ban, email...',
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
          onPressed: _showImportDialog,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.export,
          color: Colors.green,
          tooltip: 'Export dữ liệu',
          onPressed: _showExportDialog,
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
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
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
            width: MediaQuery.of(context).size.width - 32,
            child: DataTable2(
              columnSpacing: 12,
              minWidth: 800,
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
              columns: [
                DataColumn2(
                  label: const Text('Phòng ban'),
                  size: ColumnSize.L,
                  onSort: controller.sortById,
                ),
                DataColumn2(label: const Text('Mail To'), size: ColumnSize.L),
                DataColumn2(label: const Text('Mail CC'), size: ColumnSize.L),
                const DataColumn2(label: Text('Hành động'), fixedWidth: 120),
              ],
              rows: controller.filterdataList
                  .map((data) => _buildDataRow(data))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow2 _buildDataRow(Map<String, String> data) {
    return DataRow2(
      onTap: () => _showDetailDialog(data),
      cells: [
        DataCell(
          Text(
            data['Column1'] ?? "",
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(Text(data['Column2'] ?? "", overflow: TextOverflow.ellipsis)),
        DataCell(Text(data['Column3'] ?? "", overflow: TextOverflow.ellipsis)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Iconsax.edit_2, size: 20, color: Colors.blue),
                //onPressed: () => _showEditDialog(data),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ShowEditDialog(
                      data: data,
                      onUpdate: (updatedData) {
                        // Gọi hàm cập nhật dữ liệu ở đây
                        controller.updateItem(data, updatedData);
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Iconsax.trash, size: 20, color: Colors.red),
                onPressed: () => _showDeleteDialog(data),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showImportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Import Dữ Liệu PTHC'),
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
              onPressed: () {
                // Xử lý chọn file
              },
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
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              // Xử lý import
              Get.back();
              Get.snackbar(
                'Thành công',
                'Đã import dữ liệu',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
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
        title: const Text('Export Dữ Liệu PTHC'),
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
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              // Xử lý export
              Get.back();
              Get.snackbar(
                'Thành công',
                'Đã export dữ liệu',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
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
    final emailController = TextEditingController();
    final ccController = TextEditingController();
    final deptController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Thêm PTHC Mới'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: deptController,
                  decoration: InputDecoration(
                    labelText: 'Phòng ban',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập phòng ban';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Mail To (phân cách bằng dấu phẩy)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ccController,
                  decoration: InputDecoration(
                    labelText: 'Mail CC (phân cách bằng dấu phẩy)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.addItem({
                  'Column1': deptController.text,
                  'Column2': emailController.text,
                  'Column3': ccController.text,
                });
                Get.back();
                Get.snackbar(
                  'Thành công',
                  'Đã thêm PTHC mới',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
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

  void _showEditDialog(Map<String, String> data) {
    final emailController = TextEditingController(text: data['Column2']);
    final ccController = TextEditingController(text: data['Column3']);
    final deptController = TextEditingController(text: data['Column1']);

    Get.dialog(
      AlertDialog(
        title: const Text('Chỉnh sửa PTHC'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: deptController,
                  decoration: InputDecoration(
                    labelText: 'Phòng ban',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập phòng ban';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Mail To',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ccController,
                  decoration: InputDecoration(
                    labelText: 'Mail CC',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.updateItem(data, {
                  'Column1': deptController.text,
                  'Column2': emailController.text,
                  'Column3': ccController.text,
                });
                Get.back();
                Get.snackbar(
                  'Thành công',
                  'Đã cập nhật PTHC',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, String> data) {
    Get.dialog(
      AlertDialog(
        title: Text('Chi tiết PTHC: ${data['Column1']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Phòng ban:', data['Column1'] ?? ""),
              _buildDetailRow('Mail To:', data['Column2'] ?? ""),
              _buildDetailRow('Mail CC:', data['Column3'] ?? ""),
            ],
          ),
        ),
        actions: [TextButton(onPressed: Get.back, child: const Text('Đóng'))],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _showDeleteDialog(Map<String, String> data) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn chắc chắn muốn xóa PTHC ${data['Column1']}?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              controller.deleteItem(data);
              Get.back();
              Get.snackbar(
                'Thành công',
                'Đã xóa PTHC',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class DashboardControllerPTHC extends GetxController {
  var dataList = <Map<String, String>>[].obs;
  var filterdataList = <Map<String, String>>[].obs;
  final searchTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchDummyData();
  }

  void sortById(int sortColumnIndex, bool ascending) {
    filterdataList.sort((a, b) {
      final aValue = a['Column1']?.toLowerCase() ?? '';
      final bValue = b['Column1']?.toLowerCase() ?? '';
      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });
  }

  void searchQuery(String query) {
    if (query.isEmpty) {
      filterdataList.assignAll(dataList);
    } else {
      filterdataList.assignAll(
        dataList.where(
          (item) =>
              (item['Column1']?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (item['Column2']?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        ),
      );
    }
  }

  void addItem(Map<String, String> newItem) {
    dataList.add(newItem);
    filterdataList.add(newItem);
  }

  void updateItem(Map<String, String> oldItem, Map<String, String> newItem) {
    final index = dataList.indexOf(oldItem);
    if (index != -1) {
      dataList[index] = newItem;
      filterdataList[index] = newItem;
    }
  }

  void deleteItem(Map<String, String> item) {
    dataList.remove(item);
    filterdataList.remove(item);
  }

  void fetchDummyData() {
    final departments = ['RD', 'HR', 'Finance', 'Marketing', 'IT'];

    dataList.assignAll(
      List.generate(20, (index) {
        final dept = departments[index % departments.length];
        return {
          'Column1': dept,
          'Column2': '${dept.toLowerCase()}@company.com,manager@company.com',
          'Column3': 'hr@company.com,admin@company.com',
        };
      }),
    );

    filterdataList.assignAll(dataList);
  }
}

class ShowEditDialog extends StatelessWidget {
  final Map<String, String> data;
  final Function(Map<String, String>) onUpdate;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController deptController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ccController = TextEditingController();

  ShowEditDialog({Key? key, required this.data, required this.onUpdate})
    : super(key: key) {
    // Khởi tạo giá trị ban đầu cho các controller
    deptController.text = data['Column1'] ?? '';
    emailController.text = data['Column2'] ?? '';
    ccController.text = data['Column3'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: AlertDialog(
        title: const Text('Chỉnh sửa PTHC'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: deptController,
                  decoration: InputDecoration(
                    labelText: 'Phòng ban',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập phòng ban';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Mail To',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ccController,
                  decoration: InputDecoration(
                    labelText: 'Mail CC',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                onUpdate({
                  'Column1': deptController.text,
                  'Column2': emailController.text,
                  'Column3': ccController.text,
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã cập nhật PTHC'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
