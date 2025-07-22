import 'dart:io';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/custom_field.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class ApprenticeContract extends StatefulWidget {
  const ApprenticeContract({super.key});

  @override
  State<ApprenticeContract> createState() => _ApprenticeContractState();
}

class _ApprenticeContractState extends State<ApprenticeContract> {
  final DashboardControllerApprentice controller = Get.put(
    DashboardControllerApprentice(),
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
                                fontSize: Common.sizeColumn,
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
          'Lập đánh giá kết thúc hợp đồng học nghề, thử việc',
          style: TextStyle(
            color: Colors.blue.withOpacity(0.9),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lập danh sách đánh giá các công nhân viên kết thực hợp đồng thử việc lên hợp đồng có thời hạn 2 năm',
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
              width: 3350,
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
                    title: 'Đào tạo lý thuyết',
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Đào tạo thực hành',
                    width: 120,
                    fontSize: Common.sizeColumn,
                    maxLines: 2,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Hoàn thành công việc',
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Khả năng học hỏi',
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Khả năng thích nghi',
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Tinh thần hỗ trợ, quan hệ với đồng nghiệp',
                    fontSize: Common.sizeColumn,
                    width: 150,
                    maxLines: 3,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Báo cáo, liên lạc, thảo thuận',
                    fontSize: Common.sizeColumn,
                    width: 130,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Chấp hành nội quy công ty',
                    fontSize: Common.sizeColumn,
                    width: 130,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Kết quả cuối cùng',
                    fontSize: Common.sizeColumn,
                    width: 150,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Ghi chú',
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Trường hợp không tuyển dụng lại điền "X"',
                    width: 170,
                    fontSize: Common.sizeColumn,
                    maxLines: 2,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: 'Lý do không tuyển dụng lại',
                    width: 170,
                    fontSize: Common.sizeColumn,
                    maxLines: 2,
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

  // void _showImportDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Import Dữ Liệu'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             'Chọn file Excel để import dữ liệu',
  //             style: TextStyle(color: Colors.grey[600]),
  //           ),
  //           const SizedBox(height: 20),
  //           ElevatedButton.icon(
  //             icon: const Icon(Iconsax.document_upload),
  //             label: const Text('Chọn File'),
  //             onPressed: () {},
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.blue,
  //               foregroundColor: Colors.white,
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 20,
  //                 vertical: 12,
  //               ),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: controller.isLoading.value
  //               ? null
  //               : () => Navigator.of(context).pop(),
  //           child: const Text('Hủy'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             // Import logic
  //             Get.back();
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.green,
  //             foregroundColor: Colors.white,
  //           ),
  //           child: const Text('Import'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  void _showImportDialog() {
    final controller = Get.find<DashboardControllerApprentice>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              onPressed: () async {
                try {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xlsx'],
                      );

                  if (result != null) {
                    controller.isLoading.value = true;

                    // Đọc file Excel
                    final file = File(result.files.single.path!);
                    final bytes = await file.readAsBytes();
                    final excel = Excel.decodeBytes(bytes);

                    // Lấy sheet đầu tiên
                    final sheet = excel.tables[excel.tables.keys.first]!;

                    // Chuẩn bị danh sách dữ liệu mới
                    List<Map<String, String>> newData = [];

                    // Bắt đầu từ hàng thứ 2 (bỏ qua header)
                    for (var i = 1; i < sheet.rows.length; i++) {
                      final row = sheet.rows[i];
                      newData.add({
                        'employeeCode': row[1]?.value.toString() ?? '',
                        'fullName': row[2]?.value.toString() ?? '',
                        'department': row[3]?.value.toString() ?? '',
                        'group': row[4]?.value.toString() ?? '',
                        'age': row[5]?.value.toString() ?? '',
                        'position': row[6]?.value.toString() ?? '',
                        'salaryGrade': row[7]?.value.toString() ?? '',
                        'contractValidity': row[8]?.value.toString() ?? '',
                        'contractEndDate': row[9]?.value.toString() ?? '',
                        'earlyLeaveCount': row[10]?.value.toString() ?? '',
                        'paidLeaveDays': row[11]?.value.toString() ?? '',
                        'unpaidLeaveDays': row[12]?.value.toString() ?? '',
                        'unreportedLeaveDays': row[13]?.value.toString() ?? '',
                        'violationCount': row[14]?.value.toString() ?? '',
                        'healthStatus': row[15]?.value.toString() ?? 'Đạt',
                        'evaluationStatus': row[16]?.value.toString() ?? 'OK',
                        'notRehire': row[17]?.value.toString() ?? 'NG',
                        'notRehireReason': row[18]?.value.toString() ?? '',
                        'reason': '',
                        'gender': '', // Có thể thêm logic xác định giới tính
                      });
                    }

                    // Cập nhật dữ liệu vào controller
                    controller.dataList.assignAll(newData);
                    controller.filterdataList.assignAll(newData);
                    controller.selectRows.assignAll(
                      List.generate(newData.length, (index) => false),
                    );

                    Get.back();
                    Get.snackbar(
                      'Thành công',
                      'Đã import ${newData.length} bản ghi',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                } catch (e) {
                  Get.snackbar(
                    'Lỗi',
                    'Import thất bại: ${e.toString()}',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                } finally {
                  controller.isLoading.value = false;
                }
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
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    final controller = Get.find<DashboardControllerApprentice>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              children: [_buildExportOption(Iconsax.document_text, 'Excel')],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                controller.isLoading.value = true;

                // Tạo file Excel
                final excel = Excel.createExcel();
                final sheet = excel['Sheet1'];

                // Thêm tiêu đề các cột
                sheet.appendRow([
                  TextCellValue('STT'),
                  TextCellValue('Mã NV'),
                  TextCellValue('Họ và tên'),
                  TextCellValue('Phòng ban'),
                  TextCellValue('Nhóm'),
                  TextCellValue('Tuổi'),
                  TextCellValue('Vị trí'),
                  TextCellValue('Bậc lương'),
                  TextCellValue('Hiệu lực HD'),
                  TextCellValue('Ngày kết thúc HD'),
                  TextCellValue('Số lần đi mượn, về sớm'),
                  TextCellValue('Nghỉ hưởng lương'),
                  TextCellValue('Nghỉ không lương'),
                  TextCellValue('Nghỉ không báo cáo'),
                  TextCellValue('Số lần vi phạm'),
                  TextCellValue('Kết quả khám sức khỏe'),
                  TextCellValue('Kết quả đánh giá'),
                  TextCellValue('Tuyển dụng lại'),
                  TextCellValue('Lý do không tuyển dụng lại'),
                ]);

                // Thêm dữ liệu từ controller
                for (int i = 0; i < controller.filterdataList.length; i++) {
                  final item = controller.filterdataList[i];
                  sheet.appendRow([
                    TextCellValue((i + 1).toString()),
                    TextCellValue(item['employeeCode'] ?? ''),
                    TextCellValue(item['fullName'] ?? ''),
                    TextCellValue(item['department'] ?? ''),
                    TextCellValue(item['group'] ?? ''),
                    TextCellValue(item['age'] ?? ''),
                    TextCellValue(item['position'] ?? ''),
                    TextCellValue(item['salaryGrade'] ?? ''),
                    TextCellValue(item['contractValidity'] ?? ''),
                    TextCellValue(item['contractEndDate'] ?? ''),
                    TextCellValue(item['earlyLeaveCount'] ?? ''),
                    TextCellValue(item['paidLeaveDays'] ?? ''),
                    TextCellValue(item['unpaidLeaveDays'] ?? ''),
                    TextCellValue(item['unreportedLeaveDays'] ?? ''),
                    TextCellValue(item['violationCount'] ?? ''),
                    TextCellValue(item['healthStatus'] ?? ''),
                    TextCellValue(item['evaluationStatus'] ?? ''),
                    TextCellValue(item['notRehire'] ?? ''),
                    TextCellValue(item['notRehireReason'] ?? ''),
                  ]);
                }

                // Lưu file tạm
                final bytes = excel.save();
                if (bytes == null) throw Exception('Không thể tạo file Excel');

                // Cho phép người dùng chọn nơi lưu
                final String? outputFile = await FilePicker.platform.saveFile(
                  dialogTitle: 'Lưu file Excel',
                  fileName:
                      'DanhSachNhanVienHocNgheThuViec_${DateTime.now().toString().replaceAll(':', '-')}.xlsx',
                  type: FileType.custom,
                  allowedExtensions: ['xlsx'],
                );

                if (outputFile != null) {
                  final file = File(outputFile);
                  await file.writeAsBytes(bytes);

                  Get.back();
                  Get.snackbar(
                    'Thành công',
                    'Đã export ${controller.filterdataList.length} nhân viên ra file Excel',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Export thất bại: ${e.toString()}',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } finally {
                controller.isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Obx(
              () => controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Export'),
            ),
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
  final DashboardControllerApprentice controller = Get.find();

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
              fontSize: Common.sizeColumn, // Added fontSize 12
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
        //5 thuộc tính đánh giá
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
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
                fontSize: Common.sizeColumn,
                color: _getStatusColor(status),
              ), // Changed to 12
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(status)),
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ), // Added fontSize 12
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'NG',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'NG',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ), // Added fontSize 12
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Stop Working',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pause_circle,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stop Working',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ), // Added fontSize 12
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Finish L/C',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Finish L/C',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ), // Added fontSize 12
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
          TextFormField(
            style: TextStyle(fontSize: Common.sizeColumn), // Added fontSize 12
            decoration: InputDecoration(
              labelText: 'Ghi chú',
              labelStyle: TextStyle(
                fontSize: Common.sizeColumn,
              ), // Added fontSize 12
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập ghi chú';
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
              style: TextStyle(
                fontSize: Common.sizeColumn,
                color: _getStatusColor(status),
              ), // Changed to 12
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
                      Text(
                        'O',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ), // Added fontSize 12
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'NG',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'X',
                        style: TextStyle(fontSize: Common.sizeColumn),
                      ), // Added fontSize 12
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
            style: TextStyle(fontSize: Common.sizeColumn), // Added fontSize 12
            decoration: InputDecoration(
              labelText: 'Lý do',
              labelStyle: TextStyle(
                fontSize: Common.sizeColumn,
              ), // Added fontSize 12
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

class DashboardControllerApprentice extends GetxController {
  var dataList = <Map<String, String>>[].obs;
  var filterdataList = <Map<String, String>>[].obs;
  RxList<bool> selectRows = <bool>[].obs;
  RxInt sortCloumnIndex = 0.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();
  var isLoading = false.obs;

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
