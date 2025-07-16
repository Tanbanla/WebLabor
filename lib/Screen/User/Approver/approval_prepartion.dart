import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/custom_field.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';

class ApprovalPrepartionScreen extends StatefulWidget {
  const ApprovalPrepartionScreen({super.key});

  @override
  State<ApprovalPrepartionScreen> createState() =>
      _ApprovalPrepartionScreenState();
}

class _ApprovalPrepartionScreenState extends State<ApprovalPrepartionScreen> {
  final DashboardControllerApporverPer controller = Get.put(
    DashboardControllerApporverPer(),
  );
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
      {'id': '1', 'name': 'Hợp đồng học nghề, thử việc'},
      {'id': '2', 'name': 'Hợp đồng 2 năm'},
    ];
    final List<Map<String, String>> _sectionsList = [
      {'id': '1', 'name': 'R&D-IT'},
      {'id': '2', 'name': 'R&D-EE'},
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
              'Loại hợp đồng: ',
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
              hint: const Text('Chọn loại hợp đồng'),
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
        // tim kiem theo phong ban
        const SizedBox(width: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Phòng ban: ',
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
              hint: const Text('Chọn phòng ban'),
              items: _sectionsList.map((confirmer) {
                return DropdownMenuItem<String>(
                  value: confirmer['id'],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Icon(
                          Icons.room_preferences,
                          color: Colors.blue,
                          size: 16,
                        ),
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
        // tim kiem theo nhóm
        const SizedBox(width: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Nhóm: ',
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
              hint: const Text('Chọn nhóm'),
              items: _sectionsList.map((confirmer) {
                return DropdownMenuItem<String>(
                  value: confirmer['id'],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Icon(
                          Icons.room_preferences,
                          color: Colors.blue,
                          size: 16,
                        ),
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
        // tim kien theo vi tri
        const SizedBox(width: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Vị trí: ',
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
              hint: const Text('Chọn vị trí'),
              items: _sectionsList.map((confirmer) {
                return DropdownMenuItem<String>(
                  value: confirmer['id'],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Icon(
                          Icons.room_preferences,
                          color: Colors.blue,
                          size: 16,
                        ),
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
        // Button xác nhận
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 150,
            height: 36,
            decoration: BoxDecoration(
              color: Common.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: const Center(
              child: Text(
                'Xác nhận',
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
          'Phê duyệt chuẩn bị',
          style: TextStyle(
            color: Common.primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Phê duyệt của nhân sự cho danh sách đánh giá các công nhân viên chuyển sang loại hợp đồng mới',
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
              width: 2470,
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
                    title: 'Loại hợp đồng',
                    width: 170,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Trường hợp không đồng ý điền "X"',
                    width: 170,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Lý do không đồng ý',
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
}

class MyData extends DataTableSource {
  final DashboardControllerApporverPer controller = Get.find();

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
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        // thuộc tính approver
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

class DashboardControllerApporverPer extends GetxController {
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
          'notRehire': 'OK',
          'notRehireReason': '',
        };
      }),
    );

    filterdataList.assignAll(dataList);
    selectRows.assignAll(List.generate(dataList.length, (index) => false));
  }
}
