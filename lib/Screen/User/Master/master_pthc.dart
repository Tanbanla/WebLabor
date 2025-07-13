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
        backgroundColor: Colors.blue,
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
            Expanded(
              child: 
              Obx(() {
                Visibility(
                    visible: false,
                    child: Text(controller.filterdataList.length.toString()),
                );
                  return _buildDataTable();
                }
              )
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
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
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
                prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                suffixIcon: controller.searchTextController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
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
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
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
              width: width-34,
              child: PaginatedDataTable2(
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.blue[50],
                ),
                showCheckboxColumn: true,
                showFirstLastButtons: true,
                rowsPerPage: 10,
                availableRowsPerPage: const [5, 10, 20, 50],
                onRowsPerPageChanged: (value) {},
                sortColumnIndex: controller.sortCloumnIndex.value,
                sortAscending: controller.sortAscending.value,
                onPageChanged: (value) {},
                renderEmptyRowsInTheEnd: false,
                sortArrowBuilder: (ascending, sorted) {
                  return Icon(
                    sorted 
                      ? ascending 
                        ? Iconsax.arrow_up_2 
                        : Iconsax.arrow_down_1
                      : Iconsax.wallet,
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
                    label: const Text('Mail To'),
                  ),
                  DataColumn2(
                    label: const Text('Mail CC'),
                  ),
                  const DataColumn2(
                    label: Text('Hành động'),
                    fixedWidth: 150,
                  ),
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
        title: const Text('Import Dữ Liệu PTHC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chọn file Excel để import dữ liệu', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.document_upload),
              label: const Text('Chọn File'),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
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
        title: const Text('Export Dữ Liệu PTHC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chọn định dạng export', style: TextStyle(color: Colors.grey[600])),
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.addItem({
                  'Column1': deptController.text,
                  'Column2': emailController.text,
                  'Column3': ccController.text,
                });
                Get.back();
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
}

class MyData extends DataTableSource {
  final DashboardControllerPTHC controller = Get.find();

  @override
  DataRow? getRow(int index) {
    final data = controller.filterdataList[index];
    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (index.isEven) {
            return Colors.grey[50];
          }
          return null;
        },
      ),
      onTap: () => _showDetailDialog(data),
      selected: controller.selectRows[index],
      onSelectChanged: (value) {
        controller.selectRows[index] = value ?? false;
        controller.selectRows.refresh();
        notifyListeners();
      },
      cells: [
        DataCell(
          Text(data['Column1'] ?? "", 
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.w500,
          ),
        )),
        DataCell(
          Text(
            data['Column2'] ?? "",
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          Text(
            data['Column3'] ?? "",
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Iconsax.edit_2,
                color: Colors.blue,
                onPressed: () => _handleEdit(data),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Iconsax.trash,
                color: Colors.red,
                onPressed: () => _handleDelete(data),
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
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
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

  void _handleEdit(Map<String, String> data) {
    final emailController = TextEditingController(text: data['Column2']);
    final ccController = TextEditingController(text: data['Column3']);
    final deptController = TextEditingController(text: data['Column1']);

    Get.dialog(
      AlertDialog(
        title: const Text('Chỉnh sửa PTHC'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: deptController,
                decoration: InputDecoration(
                  labelText: 'Phòng ban',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Mail To',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ccController,
                decoration: InputDecoration(
                  labelText: 'Mail CC',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateItem(
                data,
                {
                  'Column1': deptController.text,
                  'Column2': emailController.text,
                  'Column3': ccController.text,
                },
              );
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
        content: Text('Bạn chắc chắn muốn xóa PTHC ${data['Column1']}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              controller.deleteItem(data);
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
  int get rowCount => controller.filterdataList.length;

  @override
  int get selectedRowCount => 0;
}

class DashboardControllerPTHC extends GetxController {
  var dataList = <Map<String, String>>[].obs;
  var filterdataList = <Map<String, String>>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchDummyData();
  }

  void sortById(int sortColumnIndex, bool ascending) {
    sortAscending.value = ascending;
    filterdataList.sort((a, b) {
      final aValue = a['Column1']?.toLowerCase() ?? '';
      final bValue = b['Column1']?.toLowerCase() ?? '';
      return ascending 
          ? aValue.compareTo(bValue) 
          : bValue.compareTo(aValue);
    });
    this.sortCloumnIndex.value = sortColumnIndex;
  }

  void searchQuery(String query) {
    if (query.isEmpty) {
      filterdataList.assignAll(dataList);
    } else {
      filterdataList.assignAll(
        dataList.where((item) =>
          (item['Column1']?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (item['Column2']?.toLowerCase().contains(query.toLowerCase()) ?? false),
      ));
    }
  }

  void addItem(Map<String, String> newItem) {
    dataList.add(newItem);
    filterdataList.add(newItem);
    selectRows.add(false);
  }

  void updateItem(Map<String, String> oldItem, Map<String, String> newItem) {
    final index = dataList.indexOf(oldItem);
    if (index != -1) {
      dataList[index] = newItem;
      filterdataList[index] = newItem;
    }
  }

  void deleteItem(Map<String, String> item) {
    final index = dataList.indexOf(item);
    if (index != -1) {
      dataList.removeAt(index);
      filterdataList.removeAt(index);
      selectRows.removeAt(index);
    }
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
    selectRows.assignAll(List.generate(dataList.length, (index) => false));
  }
}