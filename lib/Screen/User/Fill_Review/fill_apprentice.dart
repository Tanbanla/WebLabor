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
    if (authState.user!.chRGroup.toString() == "PTHC" ||
        authState.user!.chRGroup.toString() == "Admin") {
      // truong hop PTHC phong ban
      controller.changeStatus("PTHC", sectionName, null);
    } else {
      // truong hop leader
      controller.changeStatus(
        '4',
        sectionName,
        authState.user!.chRUserid.toString(),
      );
    }
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
    if (authState.user!.chRGroup.toString() == "PTHC" ||
        authState.user!.chRGroup.toString() == "Admin") {
      // truong hop PTHC phong ban
      controller.changeStatus(
        'ADM-PER',
        'Leader,Supervisor,Staff,Section Manager',
      );
    } else {
      // truong hop leader
      controller.changeStatus('ADM-PER', 'Section Manager');
    }
    final RxString selectedConfirmerId = RxString('');
    final Rx<ApproverUser?> selectedConfirmer = Rx<ApproverUser?>(null);

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
                authState.user!.chRGroup.toString() == "PTHC"
                    ? tr('ChonNguoiDanhGia')
                    : tr('approver'),
                style: TextStyle(
                  color: Common.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showSearchDialog(
                  context,
                  controller.filterdataList,
                  selectedConfirmer,
                  selectedConfirmerId,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      selectedConfirmer.value != null
                          ? Text(
                              selectedConfirmer.value!.chREmployeeAdid ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Common.primaryColor.withOpacity(0.8),
                              ),
                            )
                          : Text(
                              tr('pickapprover'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Common.primaryColor.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
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
                final controllerTwo = Get.find<DashboardControllerApprentice>();
                await controllerTwo.updateListApprenticeContractFill(
                  selectedConfirmerId.value.toString(),
                  authState.user!.chRUserid.toString(),
                );
                if (authState.user!.chRGroup.toString() == "PTHC" ||
                    authState.user!.chRGroup.toString() == "Admin") {
                  // truong hop PTHC phong ban
                  await controllerTwo.changeStatus('PTHC', sectionName, null);
                } else {
                  // truong hop leader
                  await controllerTwo.changeStatus(
                    '4',
                    sectionName,
                    authState.user!.chRUserid.toString(),
                  );
                }
                if (context.mounted) {
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('sentSuccessfully')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('', '')),
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

  void _showSearchDialog(
    BuildContext context,
    List<ApproverUser> items,
    Rx<ApproverUser?> selectedConfirmer,
    RxString selectedConfirmerId,
  ) {
    final searchController = TextEditingController();
    List<ApproverUser> filteredItems = List.from(items);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                padding: EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: tr('searchapprover'),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredItems = items.where((item) {
                            final adid =
                                item.chREmployeeAdid?.toLowerCase() ?? '';
                            final name =
                                item.chREmployeeName?.toLowerCase() ?? '';
                            final searchLower = value.toLowerCase();
                            return adid.contains(searchLower) ||
                                name.contains(searchLower);
                          }).toList();
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ListTile(
                            leading: Icon(Icons.person, color: Colors.blue),
                            title: Text(item.chREmployeeAdid ?? ''),
                            subtitle: item.chREmployeeName != null
                                ? Text(item.chREmployeeName!)
                                : null,
                            onTap: () {
                              selectedConfirmer.value = item;
                              selectedConfirmerId.value =
                                  item.chREmployeeAdid ?? '';
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              width: 3420,
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
                    width: 130,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('thuchanh'),
                    width: 130,
                    fontSize: Common.sizeColumn,
                    maxLines: 2,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('congviec'),
                    width: 130,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('hochoi'),
                    width: 130,
                    fontSize: Common.sizeColumn,
                  ).toDataColumn2(),
                  DataColumnCustom(
                    title: tr('thichnghi'),
                    width: 130,
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
                  'assets/templates/HDTV.xlsx',
                );
                final excel = Excel.decodeBytes(
                  templateData.buffer.asUint8List(),
                );
                final sheet =
                    excel['Sheet1']; //?? excel[excel.tables.keys.first];
                const startRow = 8; // Dòng bắt đầu điền dữ liệu

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
                    setCellValue('J', DateTime.parse(item.dtMJoinDate!));
                  }
                  if (item.dtMEndDate != null) {
                    setCellValue('K', DateTime.parse(item.dtMEndDate!));
                  }
                  setCellValue('L', item.fLGoLeaveLate ?? '');
                  setCellValue('M', item.fLNotLeaveDay ?? '');
                  setCellValue('N', item.inTViolation ?? '');
                  setCellValue('O', item.vchRLyThuyet ?? '');
                  setCellValue('P', item.vchRThucHanh ?? '');
                  setCellValue('Q', item.vchRCompleteWork ?? '');
                  setCellValue('R', item.vchRLearnWork ?? '');
                  setCellValue('S', item.vchRThichNghi ?? '');
                  setCellValue('T', item.vchRUseful ?? '');
                  setCellValue('U', item.vchRContact ?? '');
                  setCellValue('V', item.vcHNeedViolation ?? '');
                  setCellValue('W', item.vchRReasultsLeader ?? '');
                  setCellValue('X', item.vchRNote ?? '');
                  setCellValue('Y', item.biTNoReEmployment ? "X" : "");
                  setCellValue('Z', item.vchRUseful ?? '');
                  setCellValue('AA', item.vchRLeaderEvalution ?? '');
                }

                // 3. Xuất file
                final bytes = excel.encode();
                if (bytes == null) throw Exception(tr('Notsavefile'));

                final fileName =
                    'DanhSachDanhGiaHopDongThuViec_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
  final DashboardControllerApprentice controller = Get.find();
  final BuildContext context;
  MyData(this.context);
  @override
  DataRow? getRow(int index) {
    final data = controller.filterdataList[index];
    final reasonController = TextEditingController(
      text: data.nvchRNoReEmpoyment ?? '',
    );
    final noteController = TextEditingController(text: data.vchRNote ?? '');
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
            child: Row(
              children: [
                _buildActionButton(
                  icon: Iconsax.edit_2,
                  color: Colors.blue,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _EditContractDialog(contract: data),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Iconsax.back_square,
                  color: Colors.red,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          _ReturnConApprenticetract(contract: data),
                    );
                  },
                ),
              ],
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

        // Cac thuoc tinh danh gia
        DataCell(
          Obx(() {
            final status =
                controller.filterdataList[index].vchRLyThuyet ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateVchrLythuyet(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status =
                controller.filterdataList[index].vchRThucHanh ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateThucHanh(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status =
                controller.filterdataList[index].vchRCompleteWork ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateCompleteWork(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status =
                controller.filterdataList[index].vchRLearnWork ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateStudyWork(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status =
                controller.filterdataList[index].vchRThichNghi ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateThichNghi(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status = controller.filterdataList[index].vchRUseful ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateUseful(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status = controller.filterdataList[index].vchRContact ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateContact(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status =
                controller.filterdataList[index].vcHNeedViolation ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateNoiQuy(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        DataCell(
          Obx(() {
            final status =
                controller.filterdataList[index].vchRReasultsLeader ?? 'OK';
            final intStatus = data.inTStatusId ?? 0;
            // Hiển thị trống nếu IntStatus = 3
            if (intStatus == 3) {
              return Text(''); // hoặc SizedBox.shrink()
            }
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateCuoicung(
                    data.vchREmployeeId.toString(),
                    newValue,
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        'NG',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),

        // Ghi chu
        DataCell(
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                // Chỉ update khi mất focus
                controller.updateNote(
                  data.vchREmployeeId.toString(),
                  noteController.text,
                );
              }
            },
            child: TextFormField(
              controller: noteController,
              style: TextStyle(fontSize: Common.sizeColumn),
              decoration: InputDecoration(
                labelText: tr('note'),
                labelStyle: TextStyle(fontSize: Common.sizeColumn),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Truong hop tuyen dung lai hay xong
        DataCell(
          Obx(() {
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final rawStatus =
                controller.filterdataList[index].biTNoReEmployment ?? true;
            final status = rawStatus ? 'OK' : 'NG';
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateRehireStatus(
                    data.vchREmployeeId.toString(),
                    newValue == 'OK',
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'OK',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'O',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: Colors.green,
                        ),
                      ),
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
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
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
              const SizedBox(height: 10, width: 500),

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
                      if (authState.user!.chRGroup.toString() == "PTHC" ||
                          authState.user!.chRGroup.toString() == "Admin") {
                        // truong hop PTHC phong ban
                        await controller.changeStatus(
                          'PTHC',
                          sectionName,
                          null,
                        );
                      } else {
                        // truong hop leader
                        await controller.changeStatus(
                          '4',
                          sectionName,
                          authState.user!.chRUserid.toString(),
                        );
                      }
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

// Class tu choi phe duyet
class _ReturnConApprenticetract extends StatelessWidget {
  final ApprenticeContract contract;
  final DashboardControllerApprentice controller = Get.find();

  _ReturnConApprenticetract({required this.contract});

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
          Icon(Iconsax.back_square, color: Colors.red),
          SizedBox(width: 10),
          Row(
            children: [
              Text(
                tr('reject'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Common.grayColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${contract.vchREmployeeName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Common.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('reasonReject'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Common.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildCompactTextField(
                initialValue: contract.vchRNote,
                label: tr('reasonRejectHint'),
                onChanged: (value) => edited.vchRNote = value,
                maxLines: 2,
              ),
              // TextFormField(
              //   maxLines: 4,
              //   decoration: InputDecoration(
              //     hintText: tr('reasonRejectHint'),
              //     isDense: true,
              //     contentPadding: const EdgeInsets.symmetric(
              //       horizontal: 12,
              //       vertical: 12,
              //     ),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     floatingLabelBehavior: FloatingLabelBehavior.auto,
              //   ),
              //   style: const TextStyle(fontSize: 14),
              // ),
              const SizedBox(height: 10),
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
                      if (edited.inTStatusId == 3) {
                        edited.inTStatusId = 1;
                      }else if (edited.inTStatusId == 4) {
                        edited.inTStatusId = 3;
                      }
                      if(edited.vchRNote == null || edited.vchRNote!.isEmpty){
                        errorMessage.value = tr('reasonRejectHint');
                        return;
                      }
                      await controller.updateApprenticeContract(
                        edited,
                        authState.user!.chRUserid.toString(),
                      );
                      String sectionName = authState.user!.chRSecCode
                          .toString()
                          .split(':')[1]
                          .trim();
                      // phan xem ai dang vao man so sanh
                      if (authState.user!.chRGroup.toString() == "PTHC" ||
                          authState.user!.chRGroup.toString() == "Admin") {
                        // truong hop PTHC phong ban
                        await controller.changeStatus(
                          'PTHC',
                          sectionName,
                          null,
                        );
                      } else {
                        // truong hop leader
                        await controller.changeStatus(
                          '4',
                          sectionName,
                          authState.user!.chRUserid.toString(),
                        );
                      }
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
}
