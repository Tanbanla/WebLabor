import 'dart:io';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/PTHC_controller.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, isSkiaWeb;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_labor_contract/Common/custom_field.dart';
import 'package:web_labor_contract/class/TM_PTHC.dart';

class MasterPTHC extends StatefulWidget {
  const MasterPTHC({super.key});

  @override
  State<MasterPTHC> createState() => _MasterPTHCState();
}

class _MasterPTHCState extends State<MasterPTHC> {
  final DashboardControllerPTHC controller = Get.put(DashboardControllerPTHC());
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (context) => _ShowDialogAdd());
        },
        tooltip: tr('add'),
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
            Expanded(
              child: Obx(() {
                Visibility(
                  visible: false,
                  child: Text(controller.filteredpthcList.length.toString()),
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
          tr('pthcInfo'),
          style: TextStyle(
            color: Common.primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('titlePTHC'),
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
                hintText: tr('searchhint'),
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
          tooltip: tr('import'),
          onPressed: _showImportDialog,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.export,
          color: Colors.green,
          tooltip: tr('export'),
          onPressed: _showExportDialog,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.trash,
          color: Colors.red,
          tooltip: tr('delete'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => _DeletePTHCDialog(),
            );
          },
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
                    label: Text(tr('department')),
                    fixedWidth: 150,
                    onSort: controller.sortById,
                  ),
                  DataColumn2(
                    label: Text(tr('Mailto')),
                    // fixedWidth: 150,
                  ),
                  DataColumn2(
                    label: Text(tr('MailCC')),
                    // fixedWidth: 200,
                  ),
                  DataColumn2(
                    label: Text(tr('MailBCC')),
                    // fixedWidth: 150,
                  ),
                ],
                source: MyData(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImportDialog() {
    final controller = Get.find<DashboardControllerPTHC>();
    Rx<File?> selectedFile = Rx<File?>(null);
    Rx<Uint8List?> selectedFileData = Rx<Uint8List?>(null);
    RxString fileName = ''.obs;
    RxString errorMessage = ''.obs;
    final authState = Provider.of<AuthState>(context, listen: false);

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
                        if (kIsWeb) {
                          // Xử lý web
                          await controller.importFromExcelWeb(
                            selectedFileData.value!,
                            authState.user!.chRUserid.toString(),
                          );
                        } else {
                          // Xử lý mobile/desktop
                          await controller.importFromExcel(
                            selectedFile.value!,
                            authState.user!.chRUserid.toString(),
                          );
                        }
                        // Close the dialog after successful import
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).pop(); // Close the import dialog first
                        }
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 50,
                            ),
                            title: const Text(
                              'Thành công',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Import dữ liệu thành công'),
                                const SizedBox(height: 10),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
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
    final controller = Get.find<DashboardControllerPTHC>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  TextCellValue('Mail To'),
                  TextCellValue('Mail CC'),
                  TextCellValue('Mail BCC'),
                ]);

                // Thêm dữ liệu từ controller
                for (int i = 0; i < controller.filteredpthcList.length; i++) {
                  final item = controller.filteredpthcList[i];
                  sheet.appendRow([
                    TextCellValue((i + 1).toString()),
                    TextCellValue(item.section ?? ''),
                    TextCellValue(item.mailto ?? ''),
                    TextCellValue(item.mailcc ?? ''),
                    TextCellValue(item.mailbcc ?? ''),
                  ]);
                }

                // Lưu file
                final bytes = excel.encode(); // Sử dụng encode() thay vì save()
                if (bytes == null) throw Exception('Không thể tạo file Excel');

                // Tạo tên file
                final fileName =
                    'DanhPTHCHeThong_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                    title: const Text(
                      'Thành công',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Export dữ liệu thành công'),
                        const SizedBox(height: 10),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
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
}

class MyData extends DataTableSource {
  final DashboardControllerPTHC controller = Get.find();
  final BuildContext context; // Thêm biến context

  MyData(this.context); // Thêm constructor
  @override
  DataRow? getRow(int index) {
    final data = controller.filteredpthcList[index];
    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (index.isEven) {
          return Colors.grey[50];
        }
        return null;
      }),
      cells: [
        DataCell(
          Text(data.section ?? '', style: TextStyle(color: Colors.blue[800])),
        ),
        DataCell(Text(data.mailto ?? '')),
        DataCell(Text(data.mailcc ?? '')),
        DataCell(Text(data.mailbcc ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => controller.filteredpthcList.length;

  @override
  int get selectedRowCount => 0;
}

class _DeletePTHCDialog extends StatefulWidget {
  const _DeletePTHCDialog();

  @override
  State<_DeletePTHCDialog> createState() => _DeletePTHCDialogState();
}

class _DeletePTHCDialogState extends State<_DeletePTHCDialog> {
  final DashboardControllerPTHC controller = Get.find();
  final TextEditingController _inputController = TextEditingController();
  RxString _errorMessage = ''.obs;
  RxBool _isADID = true.obs;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return AlertDialog(
        title: const Text(
          'Xóa PTHC',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Xóa bằng ADID hoặc Email'),
                      selected: _isADID.value,
                      onSelected: (selected) {
                        _isADID.value = true;
                        _inputController.clear();
                        _errorMessage.value = '';
                      },
                    ),
                  ),
                  // const SizedBox(width: 8),
                  // Expanded(
                  //   child: ChoiceChip(
                  //     label: const Text('Xóa bằng Email'),
                  //     selected: !_isADID.value,
                  //     onSelected: (selected) {
                  //       _isADID.value = false;
                  //       _inputController.clear();
                  //       _errorMessage.value = '';
                  //     },
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  labelText: _isADID.value
                      ? 'Nhập ADID cần xóa'
                      : 'Nhập Email cần xóa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  errorText: _errorMessage.value.isEmpty
                      ? null
                      : _errorMessage.value,
                ),
                onChanged: (value) => _errorMessage.value = '',
              ),
              const SizedBox(height: 8),
              if (_errorMessage.value.isNotEmpty)
                Text(
                  _errorMessage.value,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    if (_inputController.text.isEmpty) {
                      _errorMessage.value =
                          'Vui lòng nhập ${_isADID.value ? 'ADID' : 'Email'}';
                      return;
                    }

                    controller.isLoading(true);
                    try {
                      await controller.deleteAdidOrMail(_inputController.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      _errorMessage.value = 'Lỗi: ${e.toString()}';
                    } finally {
                      controller.isLoading(false);
                    }
                  },
            child: const Text('Xóa'),
          ),
        ],
      );
    });
  }
}

class _ShowDialogAdd extends StatefulWidget {
  const _ShowDialogAdd();
  @override
  State<_ShowDialogAdd> createState() => __ShowDialogAddState();
}

class __ShowDialogAddState extends State<_ShowDialogAdd> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardControllerPTHC>();
    controller.fetchSectionList();
    var userAdd = Pthc();
    RxString errorMessage = ''.obs;
    final authState = Provider.of<AuthState>(context, listen: true);
    return Obx(
      () => AlertDialog(
        title: const Text('Thêm PTHC Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nhập Mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => userAdd.vchRMail = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: 'Loại Mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['TO', 'CC', 'BCC']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  userAdd.vchRNote = value;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: 'Phòng ban',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: controller.listSection
                    .map((section) => DropdownMenuItem(
                          value: section,
                          child: Text(section),
                        ))
                    .toList(),
                onChanged: (value) {
                  userAdd.vchRCodeSection = value;
                },
              ),
              // TextField(
              //   decoration: InputDecoration(
              //     labelText: 'Phòng ban',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              //   onChanged: (value) => userAdd.vchRCodeSection = value,
              // ),
              const SizedBox(height: 12),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    errorMessage.value,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
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
            onPressed: (controller.isLoading.value)
                ? null
                : () async {
                    errorMessage.value = '';
                    if ((userAdd.vchRMail?.isEmpty ?? true) ||
                        (userAdd.vchRCodeSection?.isEmpty ?? true) ||
                        (userAdd.vchRNote?.isEmpty ?? true)) {
                      showDialog(
                        context: context,
                        builder: (context) => DialogNotification(
                          message: 'Yêu cầu không để trống thông tin',
                          title: 'Lỗi',
                          color: Colors.red,
                          icon: Icons.error,
                        ),
                      );
                      controller.isLoading(false);
                      return;
                    }
                    controller.isLoading(false);
                    try {
                      await controller.addPTHC(
                        userAdd,
                        authState.user!.chRUserid.toString(),
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        // Close the import dialog first
                      }
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 50,
                          ),
                          title: const Text(
                            'Thành công',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Thêm PHTC thành công'),
                              const SizedBox(height: 10),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      // errorMessage.value =
                      //     'Lỗi khi thêm: ${e.toString().replaceAll('', '')}';
                      showDialog(
                        context: context,
                        builder: (context) => DialogNotification(
                          message:
                              'Lỗi khi thêm: ${e.toString().replaceAll('', '')}',
                          title: 'Lỗi',
                          color: Colors.red,
                          icon: Icons.error,
                        ),
                      );
                    } finally {
                      controller.isLoading(false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
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
                  : const Text('Thêm'),
            ),
          ),
        ],
      ),
    );
  }
}
