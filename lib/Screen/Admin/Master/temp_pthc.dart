import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/Common/common.dart';

class TwoContractScreen extends StatefulWidget {
  const TwoContractScreen({super.key});

  @override
  State<TwoContractScreen> createState() => _TwoContractScreenState();
}

class _TwoContractScreenState extends State<TwoContractScreen> {
  final DashboardControllerTwo controller = Get.put(DashboardControllerTwo());
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
                  child: Text(controller.filterdataList.length.toString()),
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
          'Lập đánh giá hợp đồng không xác định thời hạn',
          style: TextStyle(
            color: Common.primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lập danh sách đánh giá các công nhân viên từ hợp đồng 2 năm lên hợp đồng không xác định thời hạn',
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
              width: 2725,
              child: PaginatedDataTable2(
                columnSpacing: 12,
                minWidth: 2000, // Increased minWidth to accommodate all columns
                horizontalMargin: 12,
                dataRowHeight: 56,
                headingRowHeight: 66,
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
                sortColumnIndex: controller.sortCloumnIndex.value,
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
                    label: const Text('STT'),
                    fixedWidth: 60,
                    onSort: controller.sortById,
                  ),
                  DataColumn2(label: const Text('Hành động'), fixedWidth: 150),
                  DataColumn2(label: const Text('Mã NV'), fixedWidth: 100),
                  DataColumn2(label: const Text('M/F'), fixedWidth: 60),
                  DataColumn2(label: const Text('Họ và tên'), fixedWidth: 180),
                  DataColumn2(label: const Text('Phòng ban'), fixedWidth: 150),
                  DataColumn2(label: const Text('Nhóm'), fixedWidth: 100),
                  DataColumn2(
                    label: const Text('Tuổi'),
                    fixedWidth: 80,
                    numeric: true,
                  ),
                  DataColumn2(label: const Text('Vị trí'), fixedWidth: 150),
                  DataColumn2(label: const Text('Bậc lương'), fixedWidth: 100),
                  DataColumn2(
                    label: const Text('Hiệu lực HD'),
                    fixedWidth: 120,
                  ),
                  DataColumn2(
                    label: const Text('Ngày kết thúc HD'),
                    fixedWidth: 150,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Số lần đi mượn, về sớm',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 110,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Nghỉ hưởng lương',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 90,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Nghỉ không lương',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 90,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Nghỉ không báo cáo',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 90,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Số lần vi phạm nội quy công ty',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 130,
                  ),
                  DataColumn2(label: const Text('Lý do')),
                  DataColumn2(
                    label: const Text(
                      'Kết quả khám sức khỏe',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 120,
                  ),
                  DataColumn2(label: const Text('Kết quả đánh giá')),
                  DataColumn2(
                    label: const Text(
                      'Trường hợp không tuyển dụng lại điền "X"',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 170,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Lý do không tuyển dụng lại',
                      style: TextStyle(height: 1.5),
                      maxLines: 2, // Giới hạn số dòng hiển thị
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: 170,
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
  final DashboardControllerTwo controller = Get.find();

  @override
  DataRow? getRow(int index) {
    final data = controller.filterdataList[index];
    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (index.isEven) {
          return Colors.grey[50];
        }
        return null;
      }),
      onTap: () => _showDetailDialog(data),
      selected: controller.selectRows[index],
      onSelectChanged: (value) {
        controller.selectRows[index] = value ?? false;
        controller.selectRows.refresh();
        notifyListeners();
      },
      cells: [
        DataCell(
          Text(
            (index + 1).toString(),
            style: TextStyle(color: Colors.blue[800]),
          ),
        ),
        //Action
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
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Iconsax.eye,
                color: Colors.green,
                onPressed: () => _showDetailDialog(data),
              ),
            ],
          ),
        ),
        DataCell(Text(data['employeeCode'] ?? "")),
        DataCell(Text(data['gender'] ?? "")),
        DataCell(Text(data['fullName'] ?? "")),
        DataCell(Text(data['department'] ?? "")),
        DataCell(Text(data['group'] ?? "")),
        DataCell(Text(data['age']?.toString() ?? "")),
        DataCell(Text(data['position'] ?? "")),
        DataCell(Text(data['salaryGrade']?.toString() ?? "")),
        DataCell(Text(data['contractValidity'] ?? "")),
        DataCell(Text(data['contractEndDate'] ?? "")),
        DataCell(Text(data['earlyLeaveCount']?.toString() ?? "")),
        DataCell(Text(data['paidLeaveDays']?.toString() ?? "")),
        DataCell(Text(data['unpaidLeaveDays']?.toString() ?? "")),
        DataCell(Text(data['unreportedLeaveDays']?.toString() ?? "")),
        DataCell(Text(data['violationCount']?.toString() ?? "")),
        //5 thuộc tính đánh giá
        DataCell(Text("")),
        DataCell(
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Sức khỏe',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng kết quả khám sức khỏe';
              }
              return null;
            },
          ),
        ),
        DataCell(
          Obx(() {
            final item = controller.filterdataList[index];
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final status = item?['evaluationStatus'] as String? ?? 'OK';
            final id = item?['employeeCode'] as String? ?? '';

            return DropdownButton<String>(
              value: status,
              underline: Container(),
              isDense: true,
              style: TextStyle(fontSize: 14, color: _getStatusColor(status)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(status)),
              items: const [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('OK'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'NG',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('NG'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Stop Working',
                  child: Row(
                    children: [
                      Icon(Icons.pause_circle, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('Stop Working'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Finish L/C',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text('Finish L/C'),
                    ],
                  ),
                ),
              ],
              onChanged: (newValue) {
                if (newValue != null && id.isNotEmpty) {
                  controller.updateEvaluationStatus(id, newValue);
                  controller.filterdataList.refresh();
                }
              },
            );
          }),
        ),
        DataCell(
          Obx(() {
            final item = controller.filterdataList[index];
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            // Lấy giá trị notRehire, mặc định là 'NG' nếu null hoặc không hợp lệ
            final rawStatus = item['notRehire'] as String?;
            final status = (rawStatus == 'OK' || rawStatus == 'NG')
                ? rawStatus
                : 'NG';
            final employeeCode = item['employeeCode'] as String? ?? '';

            return DropdownButton<String>(
              value: status,
              underline: Container(),
              isDense: true,
              style: TextStyle(fontSize: 14, color: _getStatusColor(status)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(status)),
              items: const [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('O'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'NG',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('X'),
                    ],
                  ),
                ),
              ],
              onChanged: (newValue) {
                if (newValue != null && employeeCode.isNotEmpty) {
                  controller.updateRehireStatus(employeeCode, newValue);
                  controller.filterdataList.refresh();
                }
              },
            );
          }),
        ),
        DataCell(
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Lý do',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập lý do';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'OK':
        return Colors.green;
      case 'NG':
        return Colors.red;
      case 'Stop Working':
        return Colors.orange;
      case 'Finish L/C':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

class DashboardControllerTwo extends GetxController {
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
      final aValue = a['employeeCode']?.toLowerCase() ?? '';
      final bValue = b['employeeCode']?.toLowerCase() ?? '';
      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });
    this.sortCloumnIndex.value = sortColumnIndex;
  }

  void searchQuery(String query) {
    if (query.isEmpty) {
      filterdataList.assignAll(dataList);
    } else {
      filterdataList.assignAll(
        dataList.where(
          (item) =>
              (item['employeeCode']?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false) ||
              (item['fullName']?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        ),
      );
    }
  }

  void deleteItem(Map<String, String> item) {
    dataList.remove(item);
    filterdataList.remove(item);
    selectRows.removeAt(dataList.indexOf(item));
  }

  // các trường đánh giá
  void updateReason(String employeeCode, String reason) {
    final index = dataList.indexWhere(
      (item) => item['employeeCode'] == employeeCode,
    );
    if (index != -1) {
      dataList[index]['reason'] = reason;
      dataList.refresh();
    }
  }

  void updateHealthStatus(String employeeCode, String status) {
    final index = dataList.indexWhere(
      (item) => item['employeeCode'] == employeeCode,
    );
    if (index != -1) {
      dataList[index]['healthStatus'] = status;
      dataList.refresh();
    }
  }

  void updateEvaluationStatus(String employeeCode, String status) {
    final index = dataList.indexWhere(
      (item) => item['employeeCode'] == employeeCode,
    );
    if (index != -1) {
      dataList[index]['evaluationStatus'] = status;
      dataList.refresh();
    }
  }

  void updateRehireStatus(String employeeCode, String value) {
    final index = dataList.indexWhere(
      (item) => item['employeeCode'] == employeeCode,
    );
    if (index != -1) {
      dataList[index]['notRehire'] = value;
      dataList.refresh();
    }
  }

  void updateNotRehireReason(String employeeCode, String reason) {
    final index = dataList.indexWhere(
      (item) => item['employeeCode'] == employeeCode,
    );
    if (index != -1) {
      dataList[index]['notRehireReason'] = reason;
      dataList.refresh();
    }
  }

  //
  void fetchDummyData() {
    final departments = ['RD', 'HR', 'Finance', 'Marketing', 'IT'];
    final genders = ['M', 'F'];
    final groups = ['Nhóm 1', 'Nhóm 2', 'Nhóm 3'];
    final positions = ['Nhân viên', 'Trưởng nhóm', 'Quản lý', 'Giám đốc'];

    dataList.assignAll(
      List.generate(50, (index) {
        final dept = departments[index % departments.length];
        final gender = genders[index % genders.length];
        final group = groups[index % groups.length];
        final position = positions[index % positions.length];

        return {
          'employeeCode': 'NV${1000 + index}',
          'gender': gender,
          'fullName': 'Nguyễn Văn ${String.fromCharCode(65 + index % 26)}',
          'department': dept,
          'group': group,
          'age': (25 + index % 20).toString(),
          'position': position,
          'salaryGrade': (index % 10 + 1).toString(),
          'contractValidity': 'Còn hiệu lực',
          'contractEndDate':
              '${DateTime.now().add(Duration(days: 365)).toString().substring(0, 10)}',
          'earlyLeaveCount': (index % 5).toString(),
          'paidLeaveDays': (index % 10).toString(),
          'unpaidLeaveDays': (index % 3).toString(),
          'unreportedLeaveDays': (index % 2).toString(),
          'violationCount': (index % 4).toString(),
          'evaluationStatus': 'OK', // Khởi tạo giá trị mặc định
          'healthStatus': 'Đạt',
          'notRehire': 'NG',
          'notRehireReason': '',
          'reason': '',
        };
      }),
    );

    filterdataList.assignAll(dataList);
    selectRows.assignAll(List.generate(dataList.length, (index) => false));
  }
}
