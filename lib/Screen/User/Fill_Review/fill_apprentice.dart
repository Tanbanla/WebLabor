import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/Apprentice_Contract_controller.dart';
import 'package:web_labor_contract/API/Controller/user_approver_controller.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:web_labor_contract/class/Apprentice_Contract.dart';
import 'package:web_labor_contract/class/User_Approver.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class FillApprenticeScreen extends StatefulWidget {
  const FillApprenticeScreen({super.key});

  @override
  State<FillApprenticeScreen> createState() => _FillApprenticeScreenState();
}

class _FillApprenticeScreenState extends State<FillApprenticeScreen> {
  final DashboardControllerApprentice controller = Get.put(
    DashboardControllerApprentice(),
  );
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
    String sectionName = authState.user!.chRSecCode
        .toString()
        .split(':')[1]
        .trim();
    // phan xem ai dang vao man so sanh
    // if(authState.user!.chRGroup.toString() == "PTHC"){
    //   // truong hop PTHC phong ban
    //   controller.changeStatus('3', sectionName, null);
    // }else{
    //   // truong hop leader
    //   controller.changeStatus('4', sectionName, authState.user!.chRUserid.toString());
    // }
    controller.changeStatus(
      '2',
      sectionName,
      authState.user!.chRUserid.toString(),
    );
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
    final authState = Provider.of<AuthState>(context, listen: true);
    String sectionName = authState.user!.chRSecCode
        .toString()
        .split(':')[1]
        .trim();
    final controller = Get.put(DashboardControllerUserApprover());
    controller.changeStatus(sectionName, 'Leader,Supervisor,Staff');
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
                await controllerTwo.updateListApprenticeContractFill(
                  selectedConfirmerId.value.toString(),
                  authState.user!.chRUserid.toString(),
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
          '${tr('fillEvaluation')} ${tr('trialContract')}',
          style: TextStyle(
            color: Colors.blue.withOpacity(0.9),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('hintApprenticefill'),
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
        const SizedBox(width: 8),
        buildActionButton(
          icon: Iconsax.export,
          color: Colors.green,
          tooltip: tr('export'),
          onPressed: () => _showExportDialog(),
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
                  // TextCellValue(tr('paidLeave')),
                  // TextCellValue(tr('unpaidLeave')),
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
                    TextCellValue(item.vchRNote.toString()),
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
          Center(
            child: _buildActionButton(
              icon: Iconsax.edit_2,
              color: Colors.blue,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _EditContractDialog(contract: data),
                );
              },
            ),
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
            data.nvarchaRViolation?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
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
          TextFormField(
            style: TextStyle(fontSize: Common.sizeColumn), // Added fontSize 12
            decoration: InputDecoration(
              labelText: tr('note'),
              labelStyle: TextStyle(
                fontSize: Common.sizeColumn,
              ), // Added fontSize 12
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('pleaseNote');
              }
              return null;
            },
          ),
        ),
        DataCell(Text("", style: TextStyle(fontSize: Common.sizeColumn))),
        DataCell(
          TextFormField(
            style: TextStyle(fontSize: Common.sizeColumn), // Added fontSize 12
            decoration: InputDecoration(
              labelText: tr('reason'),
              labelStyle: TextStyle(
                fontSize: Common.sizeColumn,
              ), // Added fontSize 12
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('pleaseReason');
              }
              return null;
            },
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

class _EditContractDialog extends StatelessWidget {
  final ApprenticeContract contract;
  final DashboardControllerApprentice controller = Get.find();

  _EditContractDialog({required this.contract});

  @override
  Widget build(BuildContext context) {
    final edited = ApprenticeContract.fromJson(contract.toJson());
    RxString errorMessage = ''.obs;
    final authState = Provider.of<AuthState>(context, listen: true);

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
                          edited.fLGoLeaveLate = double.tryParse(value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactTextField(
                      initialValue: contract.fLNotLeaveDay?.toString(),
                      label: tr('unreportedLeave'),
                      onChanged: (value) =>
                          edited.fLNotLeaveDay = double.tryParse(value),
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
                          edited.inTViolation = int.tryParse(value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
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
                      await controller.updateApprenticeContract(
                        edited,
                        authState.user!.chRUserid.toString(),
                      );
                      String sectionName = authState.user!.chRSecCode
                          .toString()
                          .split(':')[1]
                          .trim();
                      // phan xem ai dang vao man so sanh
                      // if(authState.user!.chRGroup.toString() == "PTHC"){
                      //   // truong hop PTHC phong ban
                      //   controller.changeStatus('3', sectionName, null);
                      // }else{
                      //   // truong hop leader
                      //   controller.changeStatus('4', sectionName, authState.user!.chRUserid.toString());
                      // }
                      await controller.changeStatus(
                        "2",
                        sectionName,
                        authState.user!.chRUserid.toString(),
                      );
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
