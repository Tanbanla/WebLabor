import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/Two_Contract_controller.dart';
import 'package:web_labor_contract/API/Controller/user_approver_controller.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/custom_field.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';
import 'package:web_labor_contract/class/Two_Contract.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:web_labor_contract/class/User_Approver.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

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
    controller.changeStatus('1', null, null);
    controller.fetchSectionList();
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
                // trigger rebuild when list changes
                Visibility(
                  visible: false,
                  child: Text(controller.filterdataList.length.toString()),
                );
                return Stack(
                  children: [
                    Positioned.fill(child: _buildDataTable()),
                    if (controller.isLoading.value)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.6),
                          child: const Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(strokeWidth: 5),
                            ),
                          ),
                        ),
                      ),
                    if (!controller.isLoading.value &&
                        controller.filterdataList.isEmpty)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No data',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproverPer() {
    final controller = Get.put(DashboardControllerUserApprover());
    controller.changeStatus('ADM-PER', 'Section Manager');
    final RxString selectedConfirmerId = RxString('');
    final Rx<ApproverUser?> selectedConfirmer = Rx<ApproverUser?>(null);
    final authState = Provider.of<AuthState>(context, listen: true);

    return Obx(() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                tr('approver1'),
                style: TextStyle(
                  color: Common.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              DropdownButton<ApproverUser>(
                value: selectedConfirmer.value,
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
                hint: Text(tr('pickapprover1')),
                items: controller.filterdataList.map((confirmer) {
                  return DropdownMenuItem<ApproverUser>(
                    value: confirmer,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              confirmer.chREmployeeName ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (ApproverUser? newValue) {
                  selectedConfirmer.value = newValue;
                  selectedConfirmerId.value = newValue?.chREmployeeAdid ?? '';
                },
              ),
              if (selectedConfirmer.value != null) const SizedBox(width: 8),
              if (selectedConfirmer.value != null)
                IconButton(
                  icon: Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    selectedConfirmer.value = null;
                    selectedConfirmerId.value = '';
                  },
                ),
            ],
          ),
          const SizedBox(width: 30),
          // Send button
          GestureDetector(
            onTap: () async {
              if (selectedConfirmer.value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('pleasecomfirm')),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                final controllerTwo = Get.find<DashboardControllerTwo>();
                await controllerTwo.updateListTwoContractPer(
                  selectedConfirmerId.value.toString(),
                  authState.user!.chRUserid.toString(),
                );
                await controllerTwo.changeStatus("1", null, null);
                if (context.mounted) {
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('DaGui')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${tr('sendFailed')} ${e.toString().replaceAll('', '')}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Obx(
              () => Container(
                width: 130,
                height: 36,
                decoration: BoxDecoration(
                  color: controller.isLoading.value
                      ? Colors.grey
                      : Common.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Center(
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          tr('send'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('createEvaluation') + ' ' + tr('indefiniteContract'),
          style: TextStyle(
            color: Common.primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('hinttwocreate'),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  tr('searchhint'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
                const SizedBox(width: 12),
                _buildFilterFieldWithIcon(
                  width: 140,
                  hint: tr('employeeCode'),
                  icon: Iconsax.tag,
                  onChanged: (value) {
                    controller.filterByEmployeeId(value);
                  },
                ),
                const SizedBox(width: 6),
                _buildFilterFieldWithIcon(
                  width: 240,
                  hint: tr('fullName'),
                  icon: Iconsax.user,
                  onChanged: (value) {
                    controller.filterByEmployeeName(value);
                  },
                ),
                const SizedBox(width: 6),
                _buildFilterFieldWithIcon(
                  width: 160,
                  hint: tr('department'),
                  icon: Iconsax.building_3,
                  onChanged: (value) {
                    controller.filterByDepartment(value);
                  },
                ),
                const SizedBox(width: 6),
                _buildFilterFieldWithIcon(
                  width: 140,
                  hint: tr('group'),
                  icon: Iconsax.people,
                  onChanged: (value) {
                    controller.filterByGroup(value);
                  },
                ),
                // reset filter
                const SizedBox(width: 8),
                buildActionButton(
                  icon: Iconsax.refresh,
                  color: Colors.blue,
                  tooltip: tr('Rfilter'),
                  onPressed: () => controller.refreshFilteredList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Action Buttons
        buildActionButton(
          icon: Iconsax.import,
          color: Colors.blue,
          tooltip: tr('import'),
          onPressed: () => _showImportDialog(),
        ),
        const SizedBox(width: 8),
        buildActionButton(
          icon: Iconsax.export,
          color: Colors.green,
          tooltip: tr('export'),
          onPressed: () => _showExportDialog(),
        ),
        const SizedBox(width: 8),
        buildActionButton(
          icon: Iconsax.add,
          color: Colors.orange,
          tooltip: tr('add'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => _showAddDialog(),
            );
          },
        ),
        const SizedBox(width: 8),
        buildActionButton(
          icon: Iconsax.trash,
          color: Colors.red,
          tooltip: tr('delete'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => _DeleteListContractDialog(),
            );
          },
        ),
      ],
    );
  }

  // Helper method to build filter input fields with icons
  Widget _buildFilterFieldWithIcon({
    required double width,
    required String hint,
    required IconData icon,
    Function(String)? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        style: TextStyle(fontSize: 15, color: Colors.grey[800]),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black54, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5),
          ),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
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
              width: 2420,
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
                rowsPerPage: 30,
                availableRowsPerPage: const [30, 50, 100, 150],
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
                    title: tr('stt'),
                    width: 70,
                    onSort: controller.sortById,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  // DataColumn2
                  DataColumnCustom(
                    title: tr('action'),
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('employeeCode'),
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('gender'),
                    width: 60,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('fullName'),
                    width: 180,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('department'),
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    maxLines: 2,
                    title: tr('group'),
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('age'),
                    width: 70,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('position'),
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('salaryGrade'),
                    width: 100,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('contractEffective'),
                    width: 120,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('contractEndDate'),
                    width: 120,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('earlyLateCount'),
                    width: 110,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('paidLeave'),
                    width: 100,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('unpaidLeave'),
                    width: 90,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('unreportedLeave'),
                    width: 90,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('violationCount'),
                    width: 130,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('reason'),
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('TruongPhong'),
                    width: 170,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('LydoTuChoi'),
                    width: 170,
                    maxLines: 2,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
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
    final controller = Get.find<DashboardControllerTwo>();
    Rx<File?> selectedFile = Rx<File?>(null);
    Rx<Uint8List?> selectedFileData = Rx<Uint8List?>(null);
    RxString fileName = ''.obs;
    RxString errorMessage = ''.obs;
    final authState = Provider.of<AuthState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Obx(
        () => AlertDialog(
          title: Text(tr('import')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('pickFile'), style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 20),
                if (fileName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${tr('pickedFile')}${fileName.value}',
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
                  label: Text(tr('pick')),
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
                                tr('ConnectFile') + '${e.message}';
                          } catch (e) {
                            errorMessage.value =
                                '${tr('ErrorPick')}${e.toString().replaceAll('_Namespace', '')}';
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
                  Text(tr('Doing')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(tr('Cancel')),
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
                          await controller.changeStatus("1", null, null);
                        } else {
                          // Xử lý mobile/desktop
                          await controller.importExcelMobileTwoContract(
                            selectedFile.value!,
                            authState.user!.chRUserid.toString(),
                          );
                          await controller.changeStatus("1", null, null);
                        }
                        // Close the dialog after successful import
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).pop(); // Close the import dialog first
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 50,
                              ),
                              title: Text(
                                tr('Done'),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(tr('DoneImport')),
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
                                  child: Text(tr('Cancel')),
                                ),
                              ],
                            ),
                          );
                        }
                      } on PlatformException catch (e) {
                        errorMessage.value = '${tr('ErrorSys')}${e.message}';
                      } catch (e) {
                        errorMessage.value =
                            '${tr('ErrorImport')}${e.toString().replaceAll('', '')}';
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
    final controller = Get.find<DashboardControllerTwo>();
    String manv = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('export')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('fickExport'), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Iconsax.document_text, size: 40, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text('Excel', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                controller.isLoadingExport.value = true;

                // 1. Đọc file template
                final ByteData templateData = await rootBundle.load(
                  'assets/templates/HD2N.xlsx',
                );
                final excel = Excel.decodeBytes(
                  templateData.buffer.asUint8List(),
                );

                final sheet =
                    excel['Sheet1']; //?? excel[excel.tables.keys.first];
                const startRow = 7; // Dòng bắt đầu điền dữ liệu

                // 2. Điền dữ liệu vào các ô
                for (int i = 0; i < controller.filterdataList.length; i++) {
                  final item = controller.filterdataList[i];
                  final row = startRow + i;

                  // Lấy style từ dòng mẫu (dòng 6)
                  final templateRow = startRow - 1;
                  getStyle(String column) => sheet
                      .cell(CellIndex.indexByString('$column$templateRow'))
                      .cellStyle;

                  // Điền dữ liệu với style được copy từ template
                  void setCellValue(String column, dynamic value) {
                    final cell = sheet.cell(
                      CellIndex.indexByString('$column$row'),
                    );
                    cell.value = value is DateTime
                        ? TextCellValue(DateFormat('yyyy-MM-dd').format(value))
                        : TextCellValue(value.toString());
                    cell.cellStyle = getStyle(column);
                  }

                  manv = item.vchREmployeeId ?? '';
                  // Điền từng giá trị vào các cột
                  setCellValue('A', i + 1);
                  setCellValue('B', item.vchREmployeeId ?? '');
                  setCellValue('C', item.vchRTyperId ?? '');
                  setCellValue('D', item.vchREmployeeName ?? '');
                  setCellValue('E', item.vchRNameSection ?? '');
                  setCellValue('F', item.chRCostCenterName ?? '');
                  setCellValue('G', getAgeFromBirthday(item.dtMBrithday));
                  setCellValue('H', item.chRPosition ?? '');
                  setCellValue('I', item.chRCodeGrade ?? '');
                  if (item.dtMJoinDate != null) {
                    setCellValue(
                      'J',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(item.dtMJoinDate!)),
                    );
                  }
                  if (item.dtMEndDate != null) {
                    setCellValue(
                      'K',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(item.dtMEndDate!)),
                    );
                  }
                  setCellValue('L', item.fLGoLeaveLate ?? "0");
                  setCellValue('M', item.fLPaidLeave ?? "0");
                  setCellValue('N', item.fLNotPaidLeave ?? "0");
                  setCellValue('O', item.fLNotLeaveDay ?? "0");
                  setCellValue('P', item.inTViolation ?? "0");
                  setCellValue('Q', item.nvarchaRViolation ?? '');
                  setCellValue(
                    'R',
                    item.inTStatusId == 3 ? "" : (item.nvchRCompleteWork ?? ''),
                  );
                  setCellValue(
                    'S',
                    item.inTStatusId == 3 ? "" : (item.nvchRUseful ?? ''),
                  );
                  setCellValue(
                    'T',
                    item.inTStatusId == 3 ? "" : (item.nvchROther ?? ''),
                  );
                  setCellValue(
                    'U',
                    item.inTStatusId == 3
                        ? ""
                        : (item.vchRReasultsLeader ?? ''),
                  );
                  setCellValue(
                    'V',
                    item.inTStatusId == 3 ? "" : (item.vchRNote ?? ''),
                  );
                  setCellValue(
                    'W',
                    item.biTNoReEmployment == null
                        ? ""
                        : (item.biTNoReEmployment ? "" : "X"),
                  );
                  setCellValue('X', item.nvchRNoReEmpoyment ?? '');
                }

                // 3. Xuất file
                final bytes = excel.encode();
                if (bytes == null) throw Exception(tr('Notsavefile'));

                final fileName =
                    'DanhSachDanhGiaHopDong2nam_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

                if (kIsWeb) {
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
                  final String? outputFile = await FilePicker.platform.saveFile(
                    dialogTitle: tr('savefile'),
                    fileName: fileName,
                    type: FileType.custom,
                    allowedExtensions: ['xlsx'],
                  );

                  if (outputFile != null) {
                    await File(outputFile).writeAsBytes(bytes, flush: true);
                  }
                }

                // 4. Hiển thị thông báo
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 50,
                      ),
                      title: Text(
                        tr('Done'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('exportDone')),
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
                          child: Text(tr('Cancel')),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('${tr('exportError')}${e.toString()}$manv'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('Cancel')),
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
                  : Text(tr('Export')),
            ),
          ),
        ],
      ),
    );
  }

  String getAgeFromBirthday(String? birthday) {
    if (birthday == null || birthday.isEmpty) return '';
    try {
      final birthDate = DateTime.parse(birthday);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return '$age';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class MyData extends DataTableSource {
  final DashboardControllerTwo controller = Get.find();
  final BuildContext context;

  MyData(this.context);

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildCopyCell(String? value) {
    final txt = value ?? '';
    return InkWell(
      onTap: () => _copyToClipboard(txt),
      child: Row(
        children: [
          Icon(Icons.copy, size: 14, color: Colors.grey[600]),
          Text(
            txt,
            style: TextStyle(fontSize: Common.sizeColumn),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  DataRow? getRow(int index) {
    final data = controller.filterdataList[index];
    final reasonController = TextEditingController(
      text: data.nvchRApproverPer ?? '',
    );
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        _EditTwoContractDialog(twoContract: data),
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
                    builder: (context) =>
                        _DeleteTwoContractDialog(id: (data.id ?? 0)),
                  );
                },
              ),
              // const SizedBox(width: 8),
              // _buildActionButton(
              //   icon: Iconsax.eye,
              //   color: Colors.green,
              //   onPressed: () {}, //=> _showDetailDialog(data),
              // ),
            ],
          ),
        ),
        // Copyable vchREmployeeId
        DataCell(_buildCopyCell(data.vchREmployeeId)),
        DataCell(
          Center(
            child: Text(
              data.vchRTyperId ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        // Copyable vchREmployeeName
        DataCell(_buildCopyCell(data.vchREmployeeName)),
        DataCell(_buildCopyCell(data.vchRNameSection ?? "")),
        DataCell(_buildCopyCell(data.chRCostCenterName ?? "")),
        DataCell(
          Center(
            child: Text(
              data.dtMBrithday != null
                  ? '${DateTime.now().difference(DateTime.parse(data.dtMBrithday!)).inDays ~/ 365}'
                  : "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.chRPosition ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.chRCodeGrade?.toString() ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.dtMJoinDate != null
                  ? DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.parse(data.dtMJoinDate!))
                  : "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.dtMEndDate != null
                  ? DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.parse(data.dtMEndDate!))
                  : "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.fLGoLeaveLate?.toString() ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.fLPaidLeave?.toString() ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.fLNotPaidLeave?.toString() ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.fLNotLeaveDay?.toString() ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data.inTViolation?.toString() ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        //5 thuộc tính đánh giá
        DataCell(
          Text(
            data.nvarchaRViolation?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Obx(() {
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final rawStatus = data.biTApproverPer;
            if (rawStatus == false) {
              return Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'X',
                    style: TextStyle(
                      fontSize: Common.sizeColumn,
                      color: Colors.red,
                    ),
                  ),
                ],
              );
            } else {
              return Text('', style: TextStyle(fontSize: Common.sizeColumn));
            }
          }),
        ),
        DataCell(
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                // Chỉ update khi mất focus
                controller.updateNotRehireReason(
                  data.vchREmployeeId.toString(),
                  reasonController.text,
                );
              }
            },
            child: TextFormField(
              controller: reasonController,
              style: TextStyle(fontSize: Common.sizeColumn),
              decoration: InputDecoration(
                labelText: tr('reason'),
                labelStyle: TextStyle(fontSize: Common.sizeColumn),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
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

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => controller.filterdataList.length;

  @override
  int get selectedRowCount => 0;
}

class _EditTwoContractDialog extends StatelessWidget {
  final TwoContract twoContract;
  final DashboardControllerTwo controller = Get.find();

  _EditTwoContractDialog({required this.twoContract});

  @override
  Widget build(BuildContext context) {
    final edited = TwoContract.fromJson(twoContract.toJson());
    RxString errorMessage = ''.obs;
    final authState = Provider.of<AuthState>(context, listen: true);

    final RxString earlyLateError = ''.obs;
    final RxString unreportedLeaveError = ''.obs;
    final RxString violationError = ''.obs;
    final RxString fLNotLeaveDayError = ''.obs;
    final RxString fLNotPaidLeaveError = ''.obs;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Icon(Iconsax.lamp1, color: Common.primaryColor),
          SizedBox(width: 10),
          Text(
            '${tr('edit')} ${twoContract.vchREmployeeName}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Common.primaryColor,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiêu đề phần Information
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('Information'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Common.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10, width: 500),
              // Dòng 1: Mã phòng ban + Tên phòng ban
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value:
                          controller.listSection.contains(
                            edited.vchRCodeSection,
                          )
                          ? edited.vchRCodeSection
                          : null,
                      decoration: InputDecoration(
                        labelText: tr('department'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      isExpanded: true,
                      items: controller.listSection
                          .toSet() // Ensure unique values
                          .map(
                            (section) => DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        edited.vchRCodeSection = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: twoContract.chRCostCenterName,
                      label: tr('group'),
                      onChanged: (value) => edited.chRCostCenterName = value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dòng 2: Mã NV + Giới tính
              Row(
                children: [
                  Expanded(
                    child: _buildCompactReadOnlyField(
                      value: twoContract.vchREmployeeId.toString(),
                      label: tr('employeeCode'),
                      width: 400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildCompactReadOnlyField(
                      value: twoContract.vchRTyperId.toString(),
                      label: tr('gender'),
                      width: 100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 3: Tên NV + Tuổi
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildCompactReadOnlyField(
                      value: twoContract.vchREmployeeName.toString(),
                      label: tr('fullName'),
                      width: 420,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: _buildCompactReadOnlyField(
                      value: getAgeFromBirthday(
                        twoContract.dtMBrithday,
                      ).toString(),
                      label: tr('age'),
                      width: 80,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 4: Vị trí + Bậc lương
              Row(
                children: [
                  Expanded(
                    child: _buildCompactReadOnlyField(
                      value: twoContract.chRPosition.toString(),
                      label: tr('position'),
                      width: 400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildCompactReadOnlyField(
                      value: twoContract.chRCodeGrade.toString(),
                      label: tr('salaryGrade'),
                      width: 100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 5: Ngày bắt đầu + Ngày kết thúc
              Row(
                children: [
                  Expanded(
                    child: _buildCompactReadOnlyField(
                      value: DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(twoContract.dtMJoinDate!)),
                      label: tr('contractEffective'),
                      width: 250,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactReadOnlyField(
                      value: DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(twoContract.dtMEndDate!)),
                      label: tr('contractEndDate'),
                      width: 250,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tiêu đề phần thống kê
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('titleEidt1'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Common.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Dòng 6: Đi muộn/về sớm + Nghỉ có lương
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BuildCompactTextField(
                            initialValue: twoContract.fLGoLeaveLate?.toString(),
                            label: tr('earlyLateCount'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value.isEmpty) {
                                earlyLateError.value = '';
                                edited.fLGoLeaveLate = null;
                                return;
                              }
                              if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                                earlyLateError.value = tr('onlyNumber');
                              } else {
                                earlyLateError.value = '';
                                edited.fLGoLeaveLate = double.tryParse(value);
                              }
                            },
                          ),
                          if (earlyLateError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                earlyLateError.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BuildCompactTextField(
                            initialValue: twoContract.fLPaidLeave?.toString(),
                            label: tr('paidLeave'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value.isEmpty) {
                                unreportedLeaveError.value = '';
                                edited.fLPaidLeave = null;
                                return;
                              }
                              if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                                unreportedLeaveError.value = tr('onlyNumber');
                              } else {
                                unreportedLeaveError.value = '';
                                edited.fLPaidLeave = double.tryParse(value);
                              }
                            },
                          ),
                          if (unreportedLeaveError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                unreportedLeaveError.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dòng 7: Nghỉ không lương + Không báo cáo
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BuildCompactTextField(
                            initialValue: twoContract.fLNotPaidLeave
                                ?.toString(),
                            label: tr('unpaidLeave'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value.isEmpty) {
                                fLNotPaidLeaveError.value = '';
                                edited.fLNotPaidLeave = null;
                                return;
                              }
                              if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                                fLNotPaidLeaveError.value = tr('onlyNumber');
                              } else {
                                fLNotPaidLeaveError.value = '';
                                edited.fLNotPaidLeave = double.tryParse(value);
                              }
                            },
                          ),
                          if (fLNotPaidLeaveError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                earlyLateError.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BuildCompactTextField(
                            initialValue: twoContract.fLNotLeaveDay?.toString(),
                            label: tr('unreportedLeave'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value.isEmpty) {
                                fLNotLeaveDayError.value = '';
                                edited.fLNotLeaveDay = null;
                                return;
                              }
                              if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                                fLNotLeaveDayError.value = tr('onlyNumber');
                              } else {
                                fLNotLeaveDayError.value = '';
                                edited.fLNotLeaveDay = double.tryParse(value);
                              }
                            },
                          ),
                          if (fLNotLeaveDayError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                fLNotLeaveDayError.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dòng 8: Số lần vi phạm
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BuildCompactTextField(
                            initialValue: twoContract.inTViolation?.toString(),
                            label: tr('violationCount'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              if (value.isEmpty) {
                                violationError.value = '';
                                edited.inTViolation = null;
                                return;
                              }
                              if (!RegExp(r'^\d+$').hasMatch(value)) {
                                violationError.value = tr('onlyNumber');
                              } else {
                                violationError.value = '';
                                edited.inTViolation = int.tryParse(value);
                              }
                            },
                          ),
                          if (violationError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                violationError.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildCompactTextField(
              //         initialValue: twoContract.fLGoLeaveLate?.toString(),
              //         label: tr('earlyLateCount'),
              //         onChanged: (value) =>
              //             edited.fLGoLeaveLate = double.tryParse(value),
              //         keyboardType: TextInputType.number,
              //       ),
              //     ),
              //     const SizedBox(width: 10),
              //     Expanded(
              //       child: _buildCompactTextField(
              //         initialValue: twoContract.fLPaidLeave?.toString(),
              //         label: tr('paidLeave'),
              //         onChanged: (value) =>
              //             edited.fLPaidLeave = double.tryParse(value),
              //         keyboardType: TextInputType.number,
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 10),

              // // Dòng 7: Nghỉ không lương + Không báo cáo
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildCompactTextField(
              //         initialValue: twoContract.fLNotPaidLeave?.toString(),
              //         label: tr('unpaidLeave'),
              //         onChanged: (value) =>
              //             edited.fLNotPaidLeave = double.tryParse(value),
              //         keyboardType: TextInputType.number,
              //       ),
              //     ),
              //     const SizedBox(width: 10),
              //     Expanded(
              //       child: _buildCompactTextField(
              //         initialValue: twoContract.fLNotLeaveDay?.toString(),
              //         label: tr('unreportedLeave'),
              //         onChanged: (value) =>
              //             edited.fLNotLeaveDay = double.tryParse(value),
              //         keyboardType: TextInputType.number,
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 10),

              // // Dòng 8: Số lần vi phạm + Mã phê duyệt
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildCompactTextField(
              //         initialValue: twoContract.inTViolation?.toString(),
              //         label: tr('violationCount'),
              //         onChanged: (value) =>
              //             edited.inTViolation = int.tryParse(value),
              //         keyboardType: TextInputType.number,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 12),

              // Lý do vi phạm (chiếm full width)
              _buildCompactTextField(
                initialValue: twoContract.nvarchaRViolation,
                label: tr('reason'),
                onChanged: (value) => edited.nvarchaRViolation = value,
                maxLines: 2,
              ),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: controller.isLoading.value
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(tr('Cancel')),
        ),
        Obx(
          () => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Common.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: (controller.isLoading.value)
                ? null
                : () async {
                    errorMessage.value = '';
                    controller.isLoading(false);
                    try {
                      await controller.updateTwoContract(
                        edited,
                        authState.user!.chRUserid.toString(),
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      await controller.changeStatus("1", null, null);
                      showDialog(
                        // ignore: use_build_context_synchronously
                        context: context,
                        builder: (context) => DialogNotification(
                          message: tr('MessageSuss'),
                          icon: Icons.check_circle,
                          color: Colors.green,
                          title: tr('tilteSuss'),
                        ),
                      );
                    } catch (e) {
                      errorMessage.value =
                          '${tr('ErrorUpdate')}${e.toString()}';
                    }
                  },
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(tr('Save')),
          ),
        ),
      ],
    );
  }

  // widget không được phép sửa
  Widget _buildCompactReadOnlyField({
    required String value,
    required String label,
    double? width,
  }) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ),
      ],
    );
    return content;
  }

  // widget được phép sửa
  Widget _buildCompactTextField({
    required String? initialValue,
    required String label,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      style: const TextStyle(fontSize: 14),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  // so sánh bỏ khoảng trắng
  String _removeAllSpaces(String? input) {
    if (input == null) return '';
    return input.replaceAll(RegExp(r'\s+'), '');
  }

  String getAgeFromBirthday(String? birthday) {
    if (birthday == null || birthday.isEmpty) return '';
    try {
      final birthDate = DateTime.parse(birthday);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return '$age';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class _DeleteTwoContractDialog extends StatelessWidget {
  final int id;
  final DashboardControllerTwo controller = Get.find();

  _DeleteTwoContractDialog({required this.id});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Thêm Obx để theo dõi trạng thái loading
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return AlertDialog(
        title: Text(tr('CommfirmDelete')),
        content: Text(tr('Areyoudelete')),
        actions: [
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () => Navigator.of(context).pop(),
            child: Text(tr('Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: (controller.isLoading.value)
                ? null
                : () async {
                    try {
                      await controller.deleteTwoContract(id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      await controller.changeStatus("1", null, null);
                    } catch (e) {
                      // Xử lý lỗi nếu cần
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
            child: Text(tr('delete')),
          ),
        ],
      );
    });
  }
}

class _showAddDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardControllerTwo>();
    var twoContract = TwoContract();
    RxString errorMessage = ''.obs;
    String olded = '0';
    final authState = Provider.of<AuthState>(context, listen: true);

    return AlertDialog(
      titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: EdgeInsets.all(20),
      title: Row(
        children: [
          Icon(Iconsax.lamp1, color: Common.primaryColor),
          SizedBox(width: 10),
          Text(
            '${tr('addCreateTwo')}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Common.primaryColor,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Tiêu đề phần Information
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('Information'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Common.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Dòng 1: Mã phòng ban + Tên phòng ban
              SizedBox(width: 500, child: Row(children: [
                  ],
                )),
              const SizedBox(height: 10),
              // Dòng 2: Mã NV + Giới tính
              Row(
                children: [
                  Expanded(
                    child: BuildCompactTextField(
                      label: tr('employeeCode'),
                      onChanged: (value) => twoContract.vchREmployeeId = value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dòng 5: Ngày bắt đầu + Ngày kết thúc
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerField(
                      context: context,
                      initialDate: twoContract.dtMJoinDate,
                      label: tr('contractEffective'),
                      onDateSelected: (date) {
                        twoContract.dtMJoinDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(date);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDatePickerField(
                      context: context,
                      initialDate: twoContract.dtMEndDate,
                      label: tr('contractEndDate'),
                      onDateSelected: (date) {
                        twoContract.dtMEndDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tiêu đề phần thống kê
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('titleEidt1'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Common.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Dòng 6: Đi muộn/về sớm + Nghỉ có lương
              Row(
                children: [
                  Expanded(
                    child: BuildCompactTextField(
                      label: tr('earlyLateCount'),
                      onChanged: (value) =>
                          twoContract.fLGoLeaveLate = double.tryParse(value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildCompactTextField(
                      label: tr('paidLeave'),
                      onChanged: (value) =>
                          twoContract.fLPaidLeave = double.tryParse(value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 7: Nghỉ không lương + Không báo cáo
              Row(
                children: [
                  Expanded(
                    child: BuildCompactTextField(
                      label: tr('unpaidLeave'),
                      onChanged: (value) =>
                          twoContract.fLNotPaidLeave = double.tryParse(value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildCompactTextField(
                      label: tr('unreportedLeave'),
                      onChanged: (value) =>
                          twoContract.fLNotLeaveDay = double.tryParse(value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 8: Số lần vi phạm + Mã phê duyệt
              Row(
                children: [
                  Expanded(
                    child: BuildCompactTextField(
                      label: tr('violationCount'),
                      onChanged: (value) =>
                          twoContract.inTViolation = int.tryParse(value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lý do vi phạm (chiếm full width)
              BuildCompactTextField(
                label: tr('reason'),
                onChanged: (value) => twoContract.nvarchaRViolation = value,
                maxLines: 2,
              ),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: controller.isLoading.value
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(tr('Cancel')),
        ),
        Obx(
          () => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Common.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: (controller.isLoading.value)
                ? null
                : () async {
                    errorMessage.value = '';
                    controller.isLoading(true);
                    if (twoContract.vchREmployeeId?.isEmpty ?? true) {
                      showDialog(
                        context: context,
                        builder: (context) => DialogNotification(
                          message: tr('ErrorEmployeeID'),
                          title: tr('titleFail'),
                          color: Colors.red,
                          icon: Icons.error,
                        ),
                      );
                      controller.isLoading(false);
                      return;
                    }
                    if (twoContract.dtMJoinDate?.isEmpty ?? true) {
                      showDialog(
                        context: context,
                        builder: (context) => DialogNotification(
                          message: tr('ErrorNotFill'),
                          title: tr('titleFail'),
                          color: Colors.red,
                          icon: Icons.error,
                        ),
                      );
                      controller.isLoading(false);
                      return;
                    }
                    if (twoContract.dtMEndDate?.isEmpty ?? true) {
                      showDialog(
                        context: context,
                        builder: (context) => DialogNotification(
                          message: tr('ErrorNotFill'),
                          title: tr('titleFail'),
                          color: Colors.red,
                          icon: Icons.error,
                        ),
                      );
                      controller.isLoading(false);
                      return;
                    }
                    try {
                      await controller.addTwoContract(
                        twoContract,
                        olded,
                        authState.user!.chRUserid.toString(),
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      await controller.changeStatus("1", null, null);
                      showDialog(
                        // ignore: use_build_context_synchronously
                        context: context,
                        builder: (context) => DialogNotification(
                          message: tr('MessageSuss'),
                          icon: Icons.check_circle,
                          color: Colors.green,
                          title: tr('tilteSuss'),
                        ),
                      );
                    } catch (e) {
                      // errorMessage.value =
                      //     '${tr('ErrorUpdate')}${e.toString()}';
                      showDialog(
                        context: context,
                        builder: (context) => DialogNotification(
                          message: '${tr('ErrorUpdate')}${e.toString()}',
                          title: tr('titleFail'),
                          color: Colors.red,
                          icon: Icons.error,
                        ),
                      );
                    } finally {
                      controller.isLoading(false);
                    }
                  },
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(tr('Save')),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String? initialDate,
    required String label,
    required Function(DateTime) onDateSelected,
  }) {
    final textController = TextEditingController(
      text: initialDate != null && initialDate.isNotEmpty
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(initialDate))
          : '',
    );

    return TextFormField(
      controller: textController,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: Icon(Icons.calendar_today, size: 20),
      ),
      readOnly: true,
      onTap: () async {
        final initial = initialDate != null && initialDate.isNotEmpty
            ? DateTime.parse(initialDate)
            : DateTime.now();

        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Common.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Common.primaryColor,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
          textController.text = formattedDate;
          onDateSelected(pickedDate);
        }
      },
    );
  }
}

// xóa list danh sách
class _DeleteListContractDialog extends StatelessWidget {
  final DashboardControllerTwo controller = Get.find();

  _DeleteListContractDialog();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Thêm Obx để theo dõi trạng thái loading
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return AlertDialog(
        title: Text(tr('CommfirmDelete')),
        content: Text(tr('Areyoudelete')),
        actions: [
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () => Navigator.of(context).pop(),
            child: Text(tr('Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: (controller.isLoading.value)
                ? null
                : () async {
                    try {
                      await controller.deleteListTwoContract();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      await controller.changeStatus("1", null, null);
                    } catch (e) {
                      // Xử lý lỗi nếu cần
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
            child: Text(tr('delete')),
          ),
        ],
      );
    });
  }
}
