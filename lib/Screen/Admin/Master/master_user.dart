import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:http/http.dart' as http;
import 'package:web_labor_contract/class/User.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

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
                source: MyData(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // void _showImportDialog() {
  //   final controller = Get.find<DashboardControllerUser>();
  //   Rx<File?> selectedFile = Rx<File?>(null);
  //   RxString fileName = ''.obs;

  //   showDialog(
  //     context: context,
  //     builder: (context) => Obx(
  //       () => AlertDialog(
  //         title: const Text('Import Dữ Liệu'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 'Chọn file Excel để import dữ liệu',
  //                 style: TextStyle(color: Colors.grey[600]),
  //               ),
  //               const SizedBox(height: 20),
  //               if (fileName.isNotEmpty)
  //                 Padding(
  //                   padding: const EdgeInsets.only(bottom: 10),
  //                   child: Text(
  //                     'File đã chọn: ${fileName.value}',
  //                     style: const TextStyle(fontWeight: FontWeight.bold),
  //                   ),
  //                 ),
  //               ElevatedButton.icon(
  //                 icon: const Icon(Iconsax.document_upload),
  //                 label: const Text('Chọn File'),
  //                 onPressed: controller.isLoading.value
  //                     ? null
  //                     : () async {
  //                         try {
  //                           final result = await FilePicker.platform.pickFiles(
  //                             type: FileType.custom,
  //                             allowedExtensions: ['xlsx'],
  //                             allowMultiple: false,
  //                           );

  //                           if (result != null) {
  //                             selectedFile.value = File(
  //                               result.files.single.path!,
  //                             );
  //                             fileName.value = result.files.single.name;
  //                           }
  //                         } catch (e) {
  //                           controller.showError('Lỗi khi chọn file: $e');
  //                         }
  //                       },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.blue,
  //                   foregroundColor: Colors.white,
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 20,
  //                     vertical: 12,
  //                   ),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //               ),
  //               if (controller.isLoading.value) ...[
  //                 const SizedBox(height: 20),
  //                 const CircularProgressIndicator(),
  //                 const SizedBox(height: 10),
  //                 const Text('Đang xử lý...'),
  //               ],
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: controller.isLoading.value
  //                 ? null
  //                 : () => Navigator.of(context).pop(),
  //             child: const Text('Hủy'),
  //           ),
  //           ElevatedButton(
  //             onPressed:
  //                 (controller.isLoading.value || selectedFile.value == null)
  //                 ? null
  //                 : () async {
  //                     try {
  //                       controller.isLoading(true);
  //                       await controller.importFromExcel(selectedFile.value!);

  //                       // Close the dialog after successful import
  //                       if (mounted) {
  //                         Navigator.of(context).pop();
  //                       }
  //                     } catch (e) {
  //                       controller.showError('Lỗi khi import: $e');
  //                       showDialog(
  //                           context: context,
  //                           builder: (context) => AlertDialog(
  //                             title: Text('Lỗi Import file'),
  //                             content: Text('$e'),
  //                           ),
  //                         );
  //                     } finally {
  //                       controller.isLoading(false);
  //                     }
  //                   },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               foregroundColor: Colors.white,
  //             ),
  //             child: const Text('Import'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  void _showImportDialog() {
    final controller = Get.find<DashboardControllerUser>();
    Rx<File?> selectedFile = Rx<File?>(null);
    Rx<Uint8List?> selectedFileData = Rx<Uint8List?>(null);
    RxString fileName = ''.obs;
    RxString errorMessage = ''.obs;

    showDialog(
      context: context,
      builder: (context) => Obx(
        () => AlertDialog(
          title: const Text('Import Dữ Liệu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn file Excel để import dữ liệu',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                if (fileName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'File đã chọn: ${fileName.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      errorMessage.value,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Iconsax.document_upload),
                  label: const Text('Chọn File'),
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          errorMessage.value = '';
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['xlsx', 'xls'],
                              allowMultiple: false,
                            );

                            if (result != null &&
                                result.files.single.path != null) {
                              selectedFile.value = File(
                                result.files.single.path!,
                              );
                              fileName.value = result.files.single.name;
                              if (isSkiaWeb) {
                                selectedFileData.value =
                                    result.files.single.bytes;
                              }
                            }
                          } on PlatformException catch (e) {
                            errorMessage.value =
                                'Lỗi truy cập file: ${e.message}';
                          } catch (e) {
                            errorMessage.value =
                                'Lỗi khi chọn file: ${e.toString().replaceAll('_Namespace', '')}';
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
                if (controller.isLoading.value) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text('Đang xử lý...'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed:
                  (controller.isLoading.value || selectedFile.value == null)
                  ? null
                  : () async {
                      errorMessage.value = '';
                      try {
                        controller.isLoading(true);
                        //await controller.importFromExcel(selectedFile.value!);
                        if (kIsWeb) {
                          // Xử lý web
                          await controller.importFromExcelWeb(
                            selectedFileData.value!,
                          );
                        } else {
                          // Xử lý mobile/desktop
                          await controller.importFromExcel(selectedFile.value!);
                        }
                        // Close the dialog after successful import
                        if (mounted) {
                          Navigator.of(context).pop();
                          Get.snackbar(
                            'Thành công',
                            'Import dữ liệu thành công',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        }
                      } on PlatformException catch (e) {
                        errorMessage.value = 'Lỗi hệ thống: ${e.message}';
                      } catch (e) {
                        errorMessage.value =
                            'Lỗi khi import: ${e.toString().replaceAll('', '')}';
                      } finally {
                        controller.isLoading(false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    final controller = Get.find<DashboardControllerUser>();

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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                controller.isLoadingExport.value = true;

                // Tạo file Excel
                final excel = Excel.createExcel();
                final sheet = excel['Sheet1'];

                // Thêm tiêu đề các cột
                sheet.appendRow([
                  TextCellValue('STT'),
                  TextCellValue('Phòng ban'),
                  TextCellValue('Mã nhân viên'),
                  TextCellValue('Tên nhân viên'),
                  TextCellValue('ADID'),
                  TextCellValue('Nhóm quyền'),
                  TextCellValue('Trạng thái'),
                  TextCellValue('Số ngày khóa'),
                  TextCellValue('User đăng ký'),
                  TextCellValue('Thời gian đăng ký'),
                ]);

                // Thêm dữ liệu từ controller
                for (int i = 0; i < controller.filteredUserList.length; i++) {
                  final item = controller.filteredUserList[i];
                  sheet.appendRow([
                    TextCellValue((i + 1).toString()),
                    TextCellValue(item.chRSecCode ?? ''),
                    TextCellValue(item.chREmployeeId ?? ''),
                    TextCellValue(item.nvchRNameId ?? ''),
                    TextCellValue(item.chRUserid ?? ''),
                    TextCellValue(item.chRGroup ?? ''),
                    TextCellValue(item.inTLock == 1 ? 'Delete' : 'Active'),
                    TextCellValue(item.inTLockDay?.toString() ?? ''),
                    TextCellValue(item.vchRUserCreate ?? ''),
                    TextCellValue(item.dtMCreate?.toString() ?? ''),
                  ]);
                }

                // Lưu file
                final bytes = excel.encode(); // Sử dụng encode() thay vì save()
                if (bytes == null) throw Exception('Không thể tạo file Excel');

                // Tạo tên file
                final fileName =
                    'DanhUserHeThong_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

                // Xử lý tải file xuống
                if (kIsWeb) {
                  // Cho trình duyệt web
                  final blob = html.Blob(
                    [bytes],
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  );
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.AnchorElement(href: url)
                    ..setAttribute('download', fileName)
                    ..click();
                  html.Url.revokeObjectUrl(url);
                } else {
                  // Cho mobile/desktop
                  final String? outputFile = await FilePicker.platform.saveFile(
                    dialogTitle: 'Lưu file Excel',
                    fileName: fileName,
                    type: FileType.custom,
                    allowedExtensions: ['xlsx'],
                  );

                  if (outputFile != null) {
                    final file = File(outputFile);
                    await file.writeAsBytes(bytes, flush: true);
                  }
                }

                // Đóng dialog sau khi export thành công
                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                Get.snackbar(
                  'Thành công',
                  'Đã export ${controller.filteredUserList.length} nhân viên ra file Excel',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Lỗi Export thất bại: ${e.toString()}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                }
              } finally {
                controller.isLoadingExport.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Obx(
              () => controller.isLoadingExport.value
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              // TextField(
              //   decoration: InputDecoration(
              //     labelText: 'Tên nhân viên',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 12),
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
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
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
  final BuildContext context; // Thêm biến context

  MyData(this.context); // Thêm constructor
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
          Text(
            data.chRSecCode ?? '',
            style: TextStyle(color: Colors.blue[800]),
          ),
        ),
        DataCell(Text(data.chREmployeeId ?? '')),
        DataCell(Text(data.nvchRNameId ?? '')),
        DataCell(Text(data.chRUserid ?? '')),
        DataCell(Text(data.chRGroup ?? '')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: data.inTLock == 0 ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: data.inTLock == 0
                    ? Colors.green[100]!
                    : Colors.red[100]!,
              ),
            ),
            child: Text(
              data.inTLock == 0 ? 'Active' : 'Delete',
              style: TextStyle(
                color: data.inTLock == 0 ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Iconsax.edit_2,
                color: Colors.blue,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _EditUserDialog(user: data),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Iconsax.trash,
                color: Colors.red,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _DeleteUserDialog(id: (data.id ?? 0)),
                  );
                },
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
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: color),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
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
  var isLoadingExport = false.obs;

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
          return ascending
              ? (a.id ?? 0).compareTo(b.id ?? 0)
              : (b.id ?? 0).compareTo(a.id ?? 0);
        case 1: // User ID
          return ascending
              ? (a.chRUserid ?? '').compareTo(b.chRUserid ?? '')
              : (b.chRUserid ?? '').compareTo(a.chRUserid ?? '');
        case 2: // Name
          return ascending
              ? (a.nvchRNameId ?? '').compareTo(b.nvchRNameId ?? '')
              : (b.nvchRNameId ?? '').compareTo(a.nvchRNameId ?? '');
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
              (user.chRUserid ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (user.nvchRNameId ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (user.chREmployeeId ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ),
        ),
      );
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

  // thêm người dùng
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

  Future<void> importFromExcel(File file) async {
    try {
      isLoading(true);
      // Implement your Excel parsing and data import logic here
      // 1. Parse the Excel file
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      // 2. Validate the data
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;
      // 3. Send to API or update local state
      if (rows.isEmpty || rows[0].length < 4) {
        throw Exception('File Excel không đúng định dạng');
      }
      // 4. Refresh data
      final List<User> importedUsers = [];
      // Start from row 1 (skip header row) and process until empty row
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Check if we've reached an empty row (end of data)
        if (row.isEmpty || row[2]?.value?.toString().isEmpty == true) {
          break;
        }

        // Skip rows that don't have enough columns (adjust 10 to your required minimum)
        if (row.length < 10) {
          continue;
        }

        // Create and populate user
        final user = User()
          ..chRSecCode = row[1]?.value?.toString()
          ..chREmployeeId = row[2]?.value?.toString()
          ..nvchRNameId = row[3]?.value?.toString()
          ..chRUserid = row[4]?.value?.toString()
          ..chRGroup = row[5]?.value?.toString()
          ..inTLock =
              (row[6]?.value?.toString() ?? '').toLowerCase() == "delete"
              ? 1
              : 0
          ..inTLockDay = 90
          ..vchRUserCreate = 'khanhmf'
          ..dtMCreate = DateTime.now().toString()
          ..vchRUserUpdate = null
          ..dtMUpdate = DateTime.now().toString()
          ..dtMLastLogin = DateTime.now().toString();

        // Validate required fields
        if (user.chRUserid?.isEmpty == true ||
            user.nvchRNameId?.isEmpty == true ||
            user.chREmployeeId?.isEmpty == true) {
          continue; // Skip invalid rows
        }

        importedUsers.add(user);
      }
      // 5. Send to API
      if (importedUsers.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddListUser}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'users': importedUsers.map((user) => user.toJson()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Lỗi khi gửi dữ liệu lên server');
      }

      //6 reset data
      await fetchUserData();
    } catch (e) {
      showError('Import failed: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // add list user web
  Future<void> importFromExcelWeb(Uint8List bytes) async {
    try {
      isLoading(true);

      // 1. Decode Excel file from bytes
      final excel = Excel.decodeBytes(bytes);

      // 2. Get the first sheet
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;
      // 3. Send to API or update local state
      if (rows.isEmpty || rows[0].length < 4) {
        throw Exception('File Excel không đúng định dạng');
      }
      // 4. Refresh data
      final List<User> importedUsers = [];
      // Start from row 1 (skip header row) and process until empty row
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Check if we've reached an empty row (end of data)
        if (row.isEmpty || row[2]?.value?.toString().isEmpty == true) {
          break;
        }

        // Skip rows that don't have enough columns (adjust 10 to your required minimum)
        if (row.length < 10) {
          continue;
        }

        // Create and populate user
        final user = User()
          ..chRSecCode = row[1]?.value?.toString()
          ..chREmployeeId = row[2]?.value?.toString()
          ..nvchRNameId = row[3]?.value?.toString()
          ..chRUserid = row[4]?.value?.toString()
          ..chRGroup = row[5]?.value?.toString()
          ..inTLock =
              (row[6]?.value?.toString() ?? '').toLowerCase() == "delete"
              ? 1
              : 0
          ..inTLockDay = 90
          ..vchRUserCreate = 'khanhmf'
          ..dtMCreate = DateTime.now().toString()
          ..vchRUserUpdate = null
          ..dtMUpdate = DateTime.now().toString()
          ..dtMLastLogin = null;

        // Validate required fields
        if (user.chRUserid?.isEmpty == true ||
            user.nvchRNameId?.isEmpty == true ||
            user.chREmployeeId?.isEmpty == true) {
          continue; // Skip invalid rows
        }

        importedUsers.add(user);
      }
      // 5. Send to API
      if (importedUsers.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để import');
      }

      final response = await http.post(
        Uri.parse('${Common.API}${Common.AddListUser}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'users': importedUsers.map((user) => user.toJson()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Lỗi khi gửi dữ liệu lên server');
      }

      //6 reset data
      await fetchUserData();
    } catch (e) {
      showError(
        'Import thất bại: ${e.toString().replaceAll(RegExp(r'^_Namespace:?\s*'), '')}',
      );
      rethrow;
    } finally {
      isLoading(false);
    }
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

  Future<void> deleteUser(int id, {bool logical = true}) async {
    try {
      isLoading(true);
      //final endpoint = logical ? Common.DeleteIDLogic : Common.DeleteID;
      final response = await http.delete(
        Uri.parse('${Common.API}${Common.DeleteIDLogic}$id'),
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
}

class _EditUserDialog extends StatelessWidget {
  final User user;
  final DashboardControllerUser controller = Get.find();

  _EditUserDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    final editedUser = User.fromJson(user.toJson());

    return AlertDialog(
      title: Text('Chỉnh sửa thông tin ${user.nvchRNameId}'),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: user.chRSecCode,
                decoration: const InputDecoration(
                  labelText: 'Phòng ban',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => editedUser.chRSecCode = value,
              ),
              const SizedBox(height: 12),
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
                initialValue: user.chRUserid,
                decoration: const InputDecoration(
                  labelText: 'ADID nhân viên',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => editedUser.chRUserid = value,
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
                  DropdownMenuItem(value: 1, child: Text('Delete')),
                ],
                onChanged: (value) => editedUser.inTLock = value ?? 0,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value:
                    [
                      'Admin',
                      'Per',
                      'Chief Per',
                      'PTHC',
                      'Leader',
                      'Chief Section',
                      'Manager Section',
                      'Director',
                    ].contains(user.chRGroup)
                    ? user.chRGroup
                    : 'Per',
                decoration: const InputDecoration(
                  labelText: 'Nhóm quyền',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Per', child: Text('Per')),
                  DropdownMenuItem(
                    value: 'Chief Per',
                    child: Text('Chief Per'),
                  ),
                  DropdownMenuItem(value: 'PTHC', child: Text('PTHC')),
                  DropdownMenuItem(value: 'Leader', child: Text('Leader')),
                  DropdownMenuItem(
                    value: 'Chief Section',
                    child: Text('Chief Section'),
                  ),
                  DropdownMenuItem(
                    value: 'Manager Section',
                    child: Text('Manager Section'),
                  ),
                  DropdownMenuItem(value: 'Director', child: Text('Director')),
                ],
                validator: (value) =>
                    value == null ? 'Vui lòng chọn nhóm quyền' : null,
                onChanged: (value) => editedUser.chRGroup = value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: controller.isLoading.value
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    try {
                      await controller.updateUser(editedUser);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      // Xử lý lỗi nếu cần
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
            child: const Text('Lưu'),
          ),
        ),
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
    return Obx(() {
      // Thêm Obx để theo dõi trạng thái loading
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa user này?'),
        actions: [
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    try {
                      await controller.deleteUser(id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      // Xử lý lỗi nếu cần
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
            child: const Text('Xóa'),
          ),
        ],
      );
    });
  }
}
