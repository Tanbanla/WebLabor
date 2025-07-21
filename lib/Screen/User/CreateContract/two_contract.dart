import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/custom_field.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';
import 'package:web_labor_contract/class/Two_Contract.dart';

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
            const SizedBox(height: 10),

            // Search and Action Buttons
            _buildSearchAndActions(),
            const SizedBox(height: 10),

            // User approver
            _buildApproverPer(),
            const SizedBox(height: 10),

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

  Widget _buildApproverPer() {
    String? _selectedConfirmer;

    // Danh sách người có thể xác nhận (có thể lấy từ API hoặc local)
    final List<Map<String, String>> _confirmersList = [
      {'id': '1', 'name': 'Nguyễn Văn A', 'position': 'Trưởng phòng'},
      {'id': '2', 'name': 'Trần Thị B', 'position': 'Phó phòng'},
      {'id': '3', 'name': 'Lê Văn C', 'position': 'Quản lý nhân sự'},
      {'id': '4', 'name': 'Phạm Thị D', 'position': 'Giám đốc'},
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Mã đợt phát hành: ',
              style: TextStyle(
                color: Common.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const CustomField1(
              icon: Icons.apartment,
              obscureText: false,
              hinText: 'Nhập mã đợt',
            ),
          ],
        ),
        const SizedBox(width: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Người xác nhận: ',
              style: TextStyle(
                color: Common.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            DropdownButton<String>(
              value: _selectedConfirmer,
              underline: Container(),
              isDense: true,
              style: TextStyle(
                fontSize: 14,
                color: Common.primaryColor.withOpacity(0.8),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Common.primaryColor.withOpacity(0.8),
              ),
              hint: const Text('Chọn người xác nhận'),
              items: _confirmersList.map((confirmer) {
                return DropdownMenuItem<String>(
                  value: confirmer['id'],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Icon(Icons.person, color: Colors.blue, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              confirmer['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              confirmer['position'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedConfirmer = newValue;
                });
                // Có thể thêm logic xử lý khi chọn người xác nhận ở đây
              },
            ),
            if (_selectedConfirmer != null) const SizedBox(width: 8),
            if (_selectedConfirmer != null)
              IconButton(
                icon: Icon(Icons.clear, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _selectedConfirmer = null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(width: 30),
        // Button gửi
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 130,
            height: 36,
            decoration: BoxDecoration(
              color: Common.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: const Center(
              child: Text(
                'Gửi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
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
        buildActionButton(
          icon: Iconsax.import,
          color: Colors.blue,
          tooltip: 'Import dữ liệu',
          onPressed: () => _showImportDialog(),
        ),
        const SizedBox(width: 8),
        buildActionButton(
          icon: Iconsax.export,
          color: Colors.green,
          tooltip: 'Export dữ liệu',
          onPressed: () => _showExportDialog(),
        ),
        const SizedBox(width: 8),
        buildActionButton(
          icon: Iconsax.add,
          color: Colors.orange,
          tooltip: 'Thêm mới',
          onPressed: () => _showAddDialog(),
        ),
      ],
    );
  }
  Widget _buildDataTable() {
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
              width: 2570,
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
                  DataColumnCustom(
                    title: 'STT',
                    width: 70,
                    onSort: controller.sortById,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  // DataColumn2
                  DataColumnCustom(
                    title: 'Hành động',
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Mã NV',
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'M/F',
                    width: 60,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Họ và tên',
                    width: 180,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Phòng ban',
                    width: 120,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Nhóm',
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Tuổi',
                    width: 70,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Vị trí',
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Bậc lương',
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Hiệu lực HD',
                    width: 120,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Ngày kết thúc HD',
                    width: 120,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Số lần đi mượn, về sớm',
                    width: 110,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Nghỉ hưởng lương',
                    width: 100,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Nghỉ không lương',
                    width: 90,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Nghỉ không báo cáo',
                    width: 90,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Số lần vi phạm nội quy công ty',
                    width: 130,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Lý do',
                    width: 130,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Kết quả khám sức khỏe',
                    width: 120,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Kết quả đánh giá',
                    width: 150,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Trường hợp không tuyển dụng lại điền "X"',
                    width: 170,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Lý do không tuyển dụng lại',
                    width: 170,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
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
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: Common.sizeColumn,
            ),
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
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Iconsax.trash,
                color: Colors.red,
                onPressed: (){},
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
        DataCell(
          Text(
            data['employeeCode'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['gender'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['fullName'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['department'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['group'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['age']?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['position'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['salaryGrade']?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['contractValidity'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['contractEndDate'] ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['earlyLeaveCount']?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['paidLeaveDays']?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['unpaidLeaveDays']?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['unreportedLeaveDays']?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data['violationCount']?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        //5 thuộc tính đánh giá
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(
          TextFormField(
            style: TextStyle(
              fontSize: Common.sizeColumn,
            ), // Thêm cho TextFormField
            decoration: InputDecoration(
              labelText: 'Sức khỏe',
              labelStyle: TextStyle(
                fontSize: Common.sizeColumn,
              ), // Thêm cho label
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
              style: TextStyle(
                fontSize: Common.sizeColumn, // Cập nhật font size
                color: _getStatusColor(status),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(status)),
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('OK', style: TextStyle(fontSize: Common.sizeColumn)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'NG',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('NG', style: TextStyle(fontSize: Common.sizeColumn)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Stop Working',
                  child: Row(
                    children: [
                      Icon(Icons.pause_circle, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Stop Working',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Finish L/C',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Finish L/C',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ),
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
            final rawStatus = item['notRehire'] as String?;
            final status = (rawStatus == 'OK' || rawStatus == 'NG')
                ? rawStatus
                : 'NG';
            final employeeCode = item['employeeCode'] as String? ?? '';

            return DropdownButton<String>(
              value: status,
              underline: Container(),
              isDense: true,
              style: TextStyle(
                fontSize: Common.sizeColumn, // Cập nhật font size
                color: _getStatusColor(status),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(status)),
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('O', style: TextStyle(fontSize: Common.sizeColumn)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'NG',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('X', style: TextStyle(fontSize: Common.sizeColumn)),
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
            style: TextStyle(
              fontSize: Common.sizeColumn,
            ), // Thêm cho TextFormField
            decoration: InputDecoration(
              labelText: 'Lý do',
              labelStyle: TextStyle(
                fontSize: Common.sizeColumn,
              ), // Thêm cho label
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

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => controller.filterdataList.length;

  @override
  int get selectedRowCount => 0;
}

class DashboardControllerTwo extends GetxController {
  var dataList = <TwoContract>[].obs;
  var filterdataList = <TwoContract>[].obs;
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
      final aValue = a.vchREmployeeId ?.toLowerCase() ?? '';
      final bValue = b.vchREmployeeId?.toLowerCase() ?? '';
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
              (item.vchREmployeeId?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false) ||
              (item.vchREmployeeName?.toLowerCase().contains(query.toLowerCase()) ??
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
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].chRCostCenterName = reason;
      dataList.refresh();
    }
  }

  

  void updateNotRehireReason(String employeeCode, String reason) {
    final index = dataList.indexWhere(
      (item) => item.vchREmployeeId == employeeCode,
    );
    if (index != -1) {
      dataList[index].nvchRPthcSection = reason;
      dataList.refresh();
    }
  }

  //
  void fetchDummyData() {
    
  }
}
