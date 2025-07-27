import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, isSkiaWeb;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/Apprentice_Contract_controller.dart';
import 'package:web_labor_contract/API/Controller/user_approver_controller.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:easy_localization/easy_localization.dart';
import 'package:web_labor_contract/class/Apprentice_Contract.dart';
import 'package:web_labor_contract/class/User_Approver.dart';
import 'package:excel/excel.dart' hide Border;

class ApprenticeContractScreen extends StatefulWidget {
  const ApprenticeContractScreen({super.key});

  @override
  State<ApprenticeContractScreen> createState() => _ApprenticeContractScreenState();
}

class _ApprenticeContractScreenState extends State<ApprenticeContractScreen> {
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
    final controller = Get.put(
      DashboardControllerUserApprover(
        section: 'ADM-PER',
        chucvu: 'Chief,Section Manager',
      ),
    );
    final RxString selectedConfirmerId = RxString('');
    final Rx<ApproverUser?> selectedConfirmer = Rx<ApproverUser?>(null);
    RxString errorMessage = ''.obs;

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
                tr('approver'),
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
                hint: Text(tr('pickapprover')),
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
              errorMessage.value = '';
              if (selectedConfirmer.value == null) {
                errorMessage.value = tr('pleasecomfirm');
                return;
              }
              try {
                final controllerTwo = Get.find<DashboardControllerApprentice>();
                await controllerTwo.updateListApprenticeContract(
                  selectedConfirmerId.value.toString(),
                );
              } catch (e) {
                errorMessage.value =
                    '${tr('sendFailed')} ${e.toString().replaceAll('', '')}';
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
          const SizedBox(width: 8),
          if (errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  errorMessage.value,
                  style: TextStyle(color: Colors.red, fontSize: 14),
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
          tr('createEvaluation') + ' ' + tr('trialContract'),
          style: TextStyle(
            color: Colors.blue.withOpacity(0.9),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('hintApprentice'),
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
                    width: 120,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('group'),
                    width: 100,
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
                    title: tr('lythuyet'),
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('thuchanh'),
                    width: 120,
                    fontSize: Common.sizeColumn,
                    maxLines: 2,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('congviec'),
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('hochoi'),
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('thichnghi'),
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('tinhthan'),
                    fontSize: Common.sizeColumn,
                    width: 150,
                    maxLines: 3,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('baocao'),
                    fontSize: Common.sizeColumn,
                    width: 130,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('chaphanh'),
                    fontSize: Common.sizeColumn,
                    width: 130,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('ketqua'),
                    fontSize: Common.sizeColumn,
                    width: 150,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('note'),
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('notRehirable'),
                    width: 170,
                    fontSize: Common.sizeColumn,
                    maxLines: 2,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('Lydo'),
                    width: 170,
                    fontSize: Common.sizeColumn,
                    maxLines: 2,
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
    final controller = Get.find<DashboardControllerApprentice>();
    Rx<File?> selectedFile = Rx<File?>(null);
    Rx<Uint8List?> selectedFileData = Rx<Uint8List?>(null);
    RxString fileName = ''.obs;
    RxString errorMessage = ''.obs;

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
                          );
                        } else {
                          // Xử lý mobile/desktop
                          await controller.importExcelMobileContract(
                            selectedFile.value!,
                          );
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
    final controller = Get.find<DashboardControllerApprentice>();

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
              children: [_buildExportOption(Iconsax.document_text, 'Excel')],
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

                // Tạo file Excel
                final excel = Excel.createExcel();
                final sheet = excel['Sheet1'];

                // Thêm tiêu đề các cột
                sheet.appendRow([
                  TextCellValue(tr('stt')),
                  TextCellValue(tr('employeeCode')),
                  TextCellValue(tr('gender')),
                  TextCellValue(tr('fullName')),
                  TextCellValue(tr('department')),
                  TextCellValue(tr('group')),
                  TextCellValue(tr('age')),
                  TextCellValue(tr('position')),
                  TextCellValue(tr('salaryGrade')),
                  TextCellValue(tr('contractEffective')),
                  TextCellValue(tr('contractEndDate')),
                  TextCellValue(tr('earlyLateCount')),
                  TextCellValue(tr('paidLeave')),
                  TextCellValue(tr('unpaidLeave')),
                  TextCellValue(tr('unreportedLeave')),
                  TextCellValue(tr('violationCount')),
                  TextCellValue(tr('reason')),
                  TextCellValue(tr('lythuyet')),
                  TextCellValue(tr('thuchanh')),
                  TextCellValue(tr('congviec')),
                  TextCellValue(tr('hochoi')),
                  TextCellValue(tr('thichnghi')),
                  TextCellValue(tr('tinhthan')),
                  TextCellValue(tr('baocao')),
                  TextCellValue(tr('chaphanh')),
                  TextCellValue(tr('ketqua')),
                  TextCellValue(tr('note')),
                  TextCellValue(tr('notRehirable')),
                  TextCellValue(tr('Lydo')),
                ]);

                // Thêm dữ liệu từ controller
                for (int i = 0; i < controller.filterdataList.length; i++) {
                  final item = controller.filterdataList[i];
                  sheet.appendRow([
                    TextCellValue((i + 1).toString()),
                    TextCellValue(item.vchREmployeeId ?? ''),
                    TextCellValue(item.vchRTyperId ?? ''),
                    TextCellValue(item.vchREmployeeName ?? ''),
                    TextCellValue(item.vchRNameSection ?? ''),
                    TextCellValue(item.chRCostCenterName ?? ''),
                    TextCellValue(
                      getAgeFromBirthday(item.dtMBrithday).toString(),
                    ),
                    TextCellValue(item.chRPosition ?? ''),
                    TextCellValue(item.chRCodeGrade ?? ''),
                    TextCellValue(
                      item.dtMJoinDate != null
                          ? DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.parse(item.dtMJoinDate!))
                          : '',
                    ),
                    TextCellValue(
                      item.dtMEndDate != null
                          ? DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.parse(item.dtMEndDate!))
                          : '',
                    ),
                    TextCellValue(item.fLGoLeaveLate.toString()),
                    TextCellValue(item.fLNotLeaveDay.toString()),
                    TextCellValue(item.inTViolation.toString()),
                    TextCellValue(item.nvarchaRViolation ?? ''),
                    TextCellValue(item.vchRLyThuyet.toString()),
                    TextCellValue(item.vchRThucHanh.toString()), 
                    TextCellValue(item.vchRCompleteWork.toString()),
                    TextCellValue(item.vchRLearnWork.toString()),
                    TextCellValue(item.vchRThichNghi.toString()), 
                    TextCellValue(item.vchRUseful.toString()),
                    TextCellValue(item.vchRContact.toString()), 
                    TextCellValue(item.vcHNeedViolation.toString()), 
                    TextCellValue(item.vchRReasultsLeader ?? ''),
                    TextCellValue(item.biTNoReEmployment.toString()),
                    TextCellValue(item.nvchRNoReEmpoyment ?? ''),
                  ]);
                }

                // Lưu file
                final bytes = excel.encode(); // Sử dụng encode() thay vì save()
                if (bytes == null) throw Exception(tr('Notsavefile'));

                // Tạo tên file
                final fileName =
                    'DanhSachDanhGiaHopDongHocNgheThuViec_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
                    dialogTitle: tr('savefile'),
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
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('${tr('exportError')}${e.toString()}'),
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
                  : const Text('Export'),
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
  final DashboardControllerApprentice controller = Get.find();
  final BuildContext context;

  MyData(this.context);
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
      onTap: () {},
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        _EditContractDialog(contract: data),
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
                        _DeleteContractDialog(id: (data.id ?? 0)),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Iconsax.eye,
                color: Colors.green,
                onPressed: () {}, //=> _showDetailDialog(data),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            data.vchREmployeeId ?? '',
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.vchRTyperId ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.vchREmployeeName ?? '',
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.vchRNameSection ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.chRCostCenterName ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.dtMBrithday != null
                  ? '${DateTime.now().difference(DateTime.parse(data.dtMBrithday!)).inDays ~/ 365}'
                  : "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.chRPosition ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
              data.chRCodeGrade?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
              data.dtMJoinDate != null
                  ? DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.parse(data.dtMJoinDate!))
                  : "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
              data.dtMEndDate != null
                  ? DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.parse(data.dtMEndDate!))
                  : "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
              data.fLGoLeaveLate?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.reactive.toString(),
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.fLNotLeaveDay?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.inTViolation?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            "",
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
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(
          Obx(() {
            final item = controller.filterdataList[index];
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final status = item.vchRLyThuyet ?? 'OK';
            final id = item.vchREmployeeId ?? '';

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
                  // controller.updateEvaluationStatus(id, newValue);
                  // controller.filterdataList.refresh();
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
            final rawStatus = item.vchRThucHanh;
            final status = (rawStatus == 'OK' || rawStatus == 'NG')
                ? rawStatus
                : 'NG';
            final employeeCode = item.vchREmployeeId ?? '';

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
                 //controller.updateRehireStatus(employeeCode, newValue);
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
  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => controller.filterdataList.length;

  @override
  int get selectedRowCount => 0;
}
class _EditContractDialog extends StatelessWidget {
  final ApprenticeContract contract;
  final DashboardControllerApprentice controller = Get.find();

  _EditContractDialog({required this.contract});

  @override
  Widget build(BuildContext context) {
    final edited = ApprenticeContract.fromJson(contract.toJson());
    RxString errorMessage = ''.obs;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Icon(Iconsax.lamp1, color: Common.primaryColor),
          SizedBox(width: 10),
          Text(
            '${tr('edit')} ${contract.vchREmployeeName}',
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
              const SizedBox(height: 10),
              // Dòng 1: Mã phòng ban + Tên phòng ban
              Row(
                children: [
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: contract.vchRCodeSection,
                      label: tr('department'),
                      onChanged: (value) => edited.vchRCodeSection = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: contract.chRCostCenterName,
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
                    child: _buildCompactTextField(
                      initialValue: contract.vchREmployeeId,
                      label: tr('employeeCode'),
                      onChanged: (value) => edited.vchREmployeeId = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildCompactTextField(
                      initialValue: contract.vchRTyperId,
                      label: tr('gender'),
                      onChanged: (value) => edited.vchRTyperId = value,
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
                    child: _buildCompactTextField(
                      initialValue: contract.vchREmployeeName,
                      label: tr('fullName'),
                      onChanged: (value) => edited.vchREmployeeName = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: _buildCompactTextField(
                      initialValue: getAgeFromBirthday(
                        contract.dtMBrithday,
                      ).toString(),
                      label: tr('age'),
                      onChanged: (value) => edited.dtMBrithday = value,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 4: Vị trí + Bậc lương
              Row(
                children: [
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: contract.chRPosition,
                      label: tr('position'),
                      onChanged: (value) => edited.chRPosition = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildCompactTextField(
                      initialValue: contract.chRCodeGrade,
                      label: tr('salaryGrade'),
                      onChanged: (value) => edited.chRCodeGrade = value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 5: Ngày bắt đầu + Ngày kết thúc
              Row(
                children: [
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(contract.dtMJoinDate!)),
                      label: tr('contractEffective'),
                      onChanged: (value) => edited.dtMJoinDate = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(contract.dtMEndDate!)),
                      label: tr('contractEndDate'),
                      onChanged: (value) => edited.dtMEndDate = value,
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
                    child: _buildCompactTextField(
                      initialValue: contract.fLGoLeaveLate?.toString(),
                      label: tr('earlyLateCount'),
                      onChanged: (value) =>
                          edited.fLGoLeaveLate = double.tryParse(value ?? '0'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: contract.fLNotLeaveDay?.toString(),
                      label: tr('unreportedLeave'),
                      onChanged: (value) =>
                          edited.fLNotLeaveDay = double.tryParse(value ?? '0'),
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
                    child: _buildCompactTextField(
                      initialValue: contract.inTViolation?.toString(),
                      label: tr('violationCount'),
                      onChanged: (value) =>
                          edited.inTViolation = int.tryParse(value ?? '0'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  // const SizedBox(width: 10),
                  // Expanded(
                  //   child: _buildCompactTextField(
                  //     initialValue: twoContract.vchRCodeApprover,
                  //     label: tr('CodeApprover'),
                  //     onChanged: (value) => edited.vchRCodeApprover = value,
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 12),

              // Lý do vi phạm (chiếm full width)
              _buildCompactTextField(
                initialValue: contract.nvarchaRViolation,
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
                      await controller.updateApprenticeContract(edited);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
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

class _DeleteContractDialog extends StatelessWidget {
  final int id;
  final DashboardControllerApprentice controller = Get.find();

  _DeleteContractDialog({required this.id});

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
                      await controller.deleteApprenticeContract(id);
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
            child: Text(tr('delete')),
          ),
        ],
      );
    });
  }
}

class _showAddDialog extends StatelessWidget {
  _showAddDialog();
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardControllerApprentice>();
    var twoContract = ApprenticeContract();
    RxString errorMessage = ''.obs;
    String olded = '0';
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
              SizedBox(
                width: 500,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCompactTextField(
                        label: tr('department'),
                        onChanged: (value) =>
                            twoContract.vchRCodeSection = value,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactTextField(
                        label: tr('group'),
                        onChanged: (value) =>
                            twoContract.chRCostCenterName = value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Dòng 2: Mã NV + Giới tính
              Row(
                children: [
                  Expanded(
                    child: _buildCompactTextField(
                      label: tr('employeeCode'),
                      onChanged: (value) => twoContract.vchREmployeeId = value,
                    ),
                  ),
                  // const SizedBox(width: 10),
                  // SizedBox(
                  //   width: 100,
                  //   child: _buildCompactTextField(
                  //     label: tr('gender'),
                  //     onChanged: (value) => twoContract.vchRTyperId = value,
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 3: Tên NV + Tuổi
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildCompactTextField(
                      label: tr('fullName'),
                      onChanged: (value) =>
                          twoContract.vchREmployeeName = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: _buildCompactTextField(
                      label: tr('age'),
                      onChanged: (value) => olded = value,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dòng 4: Vị trí + Bậc lương
              Row(
                children: [
                  Expanded(
                    child: _buildCompactTextField(
                      label: tr('position'),
                      onChanged: (value) => twoContract.chRPosition = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildCompactTextField(
                      label: tr('salaryGrade'),
                      onChanged: (value) => twoContract.chRCodeGrade = value,
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
                    child: _buildCompactTextField(
                      label: tr('earlyLateCount'),
                      onChanged: (value) => twoContract.fLGoLeaveLate =
                          double.tryParse(value ?? '0'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactTextField(
                      label: tr('unreportedLeave'),
                      onChanged: (value) => twoContract.fLNotLeaveDay =
                          double.tryParse(value ?? '0'),
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
                    child: _buildCompactTextField(
                      label: tr('violationCount'),
                      onChanged: (value) =>
                          twoContract.inTViolation = int.tryParse(value ?? '0'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lý do vi phạm (chiếm full width)
              _buildCompactTextField(
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
                    controller.isLoading(false);
                    try {
                      await controller.addApprenticeContract(twoContract, olded);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      errorMessage.value =
                          '${tr('ErrorUpdate')}${e.toString()}';
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

  Widget _buildCompactTextField({
    required String label,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      style: const TextStyle(fontSize: 13),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
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