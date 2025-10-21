import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/Apprentice_Contract_controller.dart';
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
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class ApprovalTrialScreen extends StatefulWidget {
  const ApprovalTrialScreen({super.key});

  @override
  State<ApprovalTrialScreen> createState() => _ApprovalTrialScreenState();
}

class _ApprovalTrialScreenState extends State<ApprovalTrialScreen> {
  final DashboardControllerApprentice controller = Get.put(
    DashboardControllerApprentice(),
  );
  final ScrollController _scrollController = ScrollController();
  // Controller nội bộ cho phân trang tùy chỉnh (theo dõi chỉ số trang thủ công)
  // Không dùng PaginatorController vì PaginatedDataTable2 phiên bản hiện tại không hỗ trợ tham số này.
  int _rowsPerPage = 50;
  int _firstRowIndex = 0; // track first row of current page
  final List<int> _availableRowsPerPage = const [50, 100, 150, 200];
  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
    // phan xem ai dang vao man so sanh
    controller.fetchPTHCData();
    controller.refreshSearch();
    controller.changeStatus(
      'approval',
      null,
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${tr('approval')} ${tr('trialContract')}',
          style: TextStyle(
            color: Colors.blue.withOpacity(0.9),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('PheDuyetApHint'),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
  Widget _buildSearchAndActions() {
    final authState = Provider.of<AuthState>(context, listen: false);
    final DashboardControllerApprentice controller =
        Get.find<DashboardControllerApprentice>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final bool isSmall = maxW < 900; // tablet / small desktop
        final bool isXSmall = maxW < 600; // narrow mobile

        double fw(double desired) {
          if (isXSmall) return maxW - 40; // almost full width
          if (isSmall) return desired.clamp(110, 240);
          return desired;
        }

        final items = <Widget>[
          if (!isXSmall)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 6),
              child: Text(
                tr('searchhint'),
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
            ),
          SizedBox(
            width: fw(240),
            child: _buildFilterFieldWithIcon(
              width: fw(240),
              hint: tr('DotDanhGia'),
              icon: Iconsax.document_filter,
              onChanged: (v) => controller.updateApproverCode(v),
            ),
          ),
          SizedBox(
            width: fw(140),
            child: _buildFilterFieldWithIcon(
              width: fw(140),
              hint: tr('employeeCode'),
              icon: Iconsax.tag,
              onChanged: (v) => controller.updateEmployeeId(v),
            ),
          ),
          SizedBox(
            width: fw(240),
            child: _buildFilterFieldWithIcon(
              width: fw(240),
              hint: tr('fullName'),
              icon: Iconsax.user,
              onChanged: (v) => controller.updateEmployeeName(v),
            ),
          ),
          SizedBox(
            width: fw(160),
            child: _buildFilterFieldWithIcon(
              width: fw(160),
              hint: tr('department'),
              icon: Iconsax.building_3,
              onChanged: (v) => controller.updateDepartment(v),
            ),
          ),
          SizedBox(
            width: fw(140),
            child: _buildFilterFieldWithIcon(
              width: fw(140),
              hint: tr('group'),
              icon: Iconsax.people,
              onChanged: (v) => controller.updateGroup(v),
            ),
          ),
          buildActionButton(
            icon: Iconsax.refresh,
            color: Colors.blue,
            tooltip: tr('Rfilter'),
            onPressed: () => controller.refreshFilteredList(),
          ),
          buildActionButton(
            icon: Iconsax.export,
            color: Colors.green,
            tooltip: tr('export'),
            onPressed: () => _showExportDialog(),
          ),
          buildActionButton(
            icon: Iconsax.back_square,
            color: Colors.orange,
            tooltip: tr('ReturnS'),
            onPressed: () =>
                _ReturnSDialog(authState.user!.chRUserid.toString()),
          ),
          GestureDetector(
            onTap: () async {
              try {
                await controller.updateListApprenticeContractApproval(
                  authState.user!.chRUserid.toString(),
                );
                controller.changeStatus(
                  'approval',
                  null,
                  authState.user!.chRUserid.toString(),
                );
                if (context.mounted) {
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
                          tr('Confirm'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: isXSmall
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('searchhint'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...items.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: w,
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: items,
                ),
        );
      },
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
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 4480, //2570,
                    child: Builder(
                      builder: (context) {
                        final dataSource = MyData(context);
                        final total = controller.filterdataList.length;
                        if (_firstRowIndex >= total && total > 0) {
                          _firstRowIndex =
                              (total - 1) - ((total - 1) % _rowsPerPage);
                        }
                        final endIndex = (_firstRowIndex + _rowsPerPage) > total
                            ? total
                            : (_firstRowIndex + _rowsPerPage);
                        final visibleCount = endIndex - _firstRowIndex;
                        return Obx(
                          () => DataTable2(
                          columnSpacing: 12,
                          minWidth: 2000,
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
                          columns: [
                            DataColumnCustom(
                              title: tr('stt'),
                              width: 70,
                              onSort: controller.sortById,
                              fontSize: Common.sizeColumn,
                            ).toDataColumn2(),
                            // DataColumn2
                            // DataColumnCustom(
                            //   title: tr('action'),
                            //   width: 100,
                            //   fontSize: Common.sizeColumn,
                            // ).toDataColumn2(),
                            DataColumnCustom(
                              title: tr('Hientrang'),
                              width: 130,
                              maxLines: 2,
                              fontSize: Common.sizeColumn,
                            ).toDataColumn2(),
                            DataColumnCustom(
                              title: tr('DotDanhGia'),
                              width: 180,
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
                              title: tr('group'),
                              maxLines: 2,
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
                            // đề xuất của phòng ban
                            DataColumnCustom(
                              title: tr('notRehirable'),
                              width: 170,
                              maxLines: 2,
                              fontSize: Common.sizeColumn,
                            ).toDataColumn2(),
                            //
                            DataColumnCustom(
                              title: tr('notRehirableReason'),
                              width: 170,
                              maxLines: 2,
                              fontSize: Common.sizeColumn,
                            ).toDataColumn2(),
                            // nguoi de xuat cua phong ban
                            DataColumnCustom(
                              title: tr('DeXuat'),
                              width: 170,
                              maxLines: 2,
                              fontSize: Common.sizeColumn,
                            ).toDataColumn2(),
                            // chief xác nhận kết quả
                            DataColumnCustom(
                              title: tr('ChiefApproval'),
                              width: 170,
                              maxLines: 2,
                              fontSize: Common.sizeColumn,
                            ).toDataColumn2(),
                            DataColumnCustom(
                              title: tr('Apporval'), //tr('notRehirable'),
                              width: 170,
                              fontSize: Common.sizeColumn,
                              maxLines: 2,
                            ).toDataColumn2(),
                            DataColumnCustom(
                              title: tr('LydoTuChoi'), //tr('Lydo'),
                              width: 170,
                              fontSize: Common.sizeColumn,
                              maxLines: 2,
                            ).toDataColumn2(),
                          ],
                          rows: List.generate(
                            visibleCount,
                            (i) => dataSource.getRow(_firstRowIndex + i)!,
                          ),
                        ));
                      },
                    ),
                  ),
                ),
              ),
            ),
            _buildCustomPaginator(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPaginator() {
    final total = controller.filterdataList.length;
    final start = total == 0 ? 0 : _firstRowIndex + 1;
    final end = (_firstRowIndex + _rowsPerPage) > total
        ? total
        : (_firstRowIndex + _rowsPerPage);

    final isFirstPage = _firstRowIndex == 0;
    final isLastPage = end >= total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Rows per page selector
          Row(
            children: [
              Text(
                tr('rowsPerPage'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  underline: const SizedBox(), // Remove default underline
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  items: _availableRowsPerPage
                      .map(
                        (e) => DropdownMenuItem<int>(
                          value: e,
                          child: Text(
                            '$e',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _rowsPerPage = v;
                        _firstRowIndex = 0;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          // Center - Page info
          Text(
            '$start - $end / $total',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),

          // Right side - Navigation buttons
          Row(
            children: [
              // First page
              IconButton(
                icon: Icon(Icons.first_page, size: 20),
                color: isFirstPage ? Colors.grey[400] : Colors.blue[600],
                tooltip: tr('firstPage'),
                onPressed: isFirstPage
                    ? null
                    : () {
                        setState(() {
                          _firstRowIndex = 0;
                        });
                      },
              ),

              // Previous page
              IconButton(
                icon: Icon(Icons.chevron_left, size: 24),
                color: isFirstPage ? Colors.grey[400] : Colors.blue[600],
                tooltip: tr('previousPage'),
                onPressed: isFirstPage
                    ? null
                    : () {
                        setState(() {
                          _firstRowIndex = (_firstRowIndex - _rowsPerPage)
                              .clamp(0, total);
                        });
                      },
              ),

              // Page indicator (optional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${(_firstRowIndex ~/ _rowsPerPage) + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Next page
              IconButton(
                icon: Icon(Icons.chevron_right, size: 24),
                color: isLastPage ? Colors.grey[400] : Colors.blue[600],
                tooltip: tr('nextPage'),
                onPressed: isLastPage
                    ? null
                    : () {
                        setState(() {
                          _firstRowIndex = (_firstRowIndex + _rowsPerPage)
                              .clamp(0, (total - 1).clamp(0, total));
                        });
                      },
              ),

              // Last page
              IconButton(
                icon: Icon(Icons.last_page, size: 20),
                color: isLastPage ? Colors.grey[400] : Colors.blue[600],
                tooltip: tr('lastPage'),
                onPressed: isLastPage
                    ? null
                    : () {
                        setState(() {
                          final remainder = total % _rowsPerPage;
                          _firstRowIndex = remainder == 0
                              ? total - _rowsPerPage
                              : total - remainder;
                        });
                      },
              ),
            ],
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
                // Xác nhận danh sách xuất dữ liệu
                List<ApprenticeContract> dataToExport =
                    controller.getSelectedItems().isNotEmpty
                    ? controller.getSelectedItems()
                    : List.from(controller.filterdataList);
                // 2. Điền dữ liệu vào các ô
                for (int i = 0; i < dataToExport.length; i++) {
                  final item = dataToExport[i];
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
                  setCellValue('L', item.fLGoLeaveLate ?? '0');
                  setCellValue('M', item.fLNotLeaveDay ?? '0');
                  setCellValue('N', item.inTViolation ?? '0');
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
                  setCellValue(
                    'Y',
                    item.biTNoReEmployment == null
                        ? ""
                        : (item.biTNoReEmployment ? "" : "X"),
                  );
                  setCellValue('Z', item.nvchRNoReEmpoyment ?? '');
                  setCellValue('AA', item.vchRLeaderEvalution ?? '');
                  setCellValue(
                    'AB',
                    item.useRApproverChief ?? '',
                  );
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
                  html.AnchorElement(href: url)
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

  void _ReturnSDialog(String adid) {
    final controller = Get.find<DashboardControllerApprentice>();
    final reasonController = TextEditingController();
    final messageError = ''.obs;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('ReturnS')),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: tr('reason'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('Cancel')),
          ),

          ElevatedButton(
            onPressed: () async {
              try {
                if (reasonController.text.isEmpty) {
                  messageError.value = tr('pleaseReason');
                  return;
                }
                await controller.updateListContractReturnS(
                  adid,
                  reasonController.text,
                );
                controller.changeStatus('approval', null, adid);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('DaGui')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${tr('sendFailed')} ${e.toString().replaceAll('', '')}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(tr('Confirm')),
          ),
          Obx(
            () => messageError.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, right: 16.0),
                    child: Text(
                      messageError.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : const SizedBox.shrink(),
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
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= controller.filterdataList.length) return null;
    final data = controller.filterdataList[index];
    final reasonController = TextEditingController(
      text: switch (data.inTStatusId) {
        5=> data.nvchRApproverChief ?? '',
        6 => data.nvchRApproverManager?? '',
        7 => data.nvchrApproverDeft?? '',
        _ => '', // Giá trị mặc định cho các trường hợp khác
      },
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
        // DataCell(
        //   Center(
        //     child: _buildActionButton(
        //       icon: Iconsax.edit_2,
        //       color: Colors.blue,
        //       onPressed: () {
        //         showDialog(
        //           context: context,
        //           builder: (context) => _EditContractDialog(contract: data),
        //         );
        //       },
        //     ),
        //   ),
        // ),
        DataCell(_getHienTrangColor(data.inTStatusId)),
        // Copyable vchRCodeApprover
        DataCell(_buildCopyCell(data.vchRCodeApprover ?? "")),
        // Copyable vchREmployeeId
        DataCell(_buildCopyCell(data.vchREmployeeId)),
        DataCell(
          Text(
            data.vchRTyperId ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        // Copyable vchREmployeeName
        DataCell(_buildCopyCell(data.vchREmployeeName)),
        DataCell(_buildCopyCell(data.vchRNameSection ?? "")),
        DataCell(_buildCopyCell(data.chRCostCenterName ?? "")),
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
          _getDanhGiaView(
            controller.filterdataList[index].vchRLyThuyet ?? 'OK',
          ),
        ),
        DataCell(
          _getDanhGiaView(
            controller.filterdataList[index].vchRThucHanh ?? 'OK',
          ),
        ),
        DataCell(
          _getDanhGiaView(
            controller.filterdataList[index].vchRCompleteWork ?? 'OK',
          ),
        ),
        DataCell(
          _getDanhGiaView(
            controller.filterdataList[index].vchRLearnWork ?? 'OK',
          ),
        ),
        DataCell(
          _getDanhGiaView(
            controller.filterdataList[index].vchRThichNghi ?? 'OK',
          ),
        ),
        DataCell(
          _getDanhGiaView(controller.filterdataList[index].vchRUseful ?? 'OK'),
        ),
        DataCell(
          _getDanhGiaView(controller.filterdataList[index].vchRContact ?? 'OK'),
        ),
        DataCell(
          _getDanhGiaView(
            controller.filterdataList[index].vcHNeedViolation ?? 'OK',
          ),
        ),
        DataCell(
          _getDanhGiaView(
            controller.filterdataList[index].vchRReasultsLeader ?? 'OK',
          ),
        ),
        // ly do k tuyen dung lai
        DataCell(
          Center(
            child: Text(
              data.nvchRNoReEmpoyment ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        // tuyển dụng lại
        DataCell(
          Obx(() {
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final rawStatus =
                controller.filterdataList[index].biTNoReEmployment ?? true;
            final status = rawStatus ? 'OK' : 'NG';
            if (status == 'OK') {
              return Row(
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
              );
            } else {
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
            }
          }),
        ),
        // ly do k tuyen dung lai
        DataCell(
          Center(
            child: Text(
              data.nvchRNoReEmpoyment ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        // nguoi de xuat cua phong ban
        DataCell(
          Text(
            data.vchRLeaderEvalution ?? '',
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        // chief xác nhận kết quả
        DataCell(
          Text(
            data.useRApproverChief ?? '',
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        // phe duyet
        DataCell(
          Obx(() {
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final rawStatus = () {
              if (controller.filterdataList.length > index) {
                return switch (data.inTStatusId) {
                  6 =>
                    controller.filterdataList[index].biTApproverSectionManager ?? true,
                  7 =>
                    controller
                            .filterdataList[index]
                            .bitApproverDeft ?? true,
                  _ => true,
                };
              }
              return true;
            }();
            final status = rawStatus ? 'OK' : 'NG';
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateRehireStatusApprovel(
                    data.vchREmployeeId.toString(),
                    newValue == 'OK',
                    data.inTStatusId,
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
                controller.updateNotRehireReasonApprovel(
                  data.vchREmployeeId.toString(),
                  reasonController.text,
                  data.inTStatusId,
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

  Widget _getHienTrangColor(int? IntStatus) {
    switch (IntStatus) {
      case 1:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey[100]!),
          ),
          child: Text('New', style: TextStyle(color: Colors.grey[800])),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Text(
            'Per/人事課の中級管理職',
            style: TextStyle(color: Colors.purple[800]),
          ),
        );
      case 3:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: Text('PTHC', style: TextStyle(color: Colors.orange[800])),
        );
      case 4:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Text('Leader', style: TextStyle(color: Colors.blue[800])),
        );
      case 5:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple[100]!),
          ),
          child: Text('Chief', style: TextStyle(color: const Color.fromARGB(255, 192, 21, 192))),
        );
      case 6:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.yellow[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.yellow[100]!),
          ),
          child: Text(
            'QLTC/中級管理職',
            style: TextStyle(color: Colors.yellow[800]),
          ),
        );
      case 7:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal[100]!),
          ),
          child: Text('QLCC/上級管理職', style: TextStyle(color: Colors.teal[800])),
        );
      case 8:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown[100]!),
          ),
          child: Text(
            'Director/管掌取締役',
            style: TextStyle(color: Colors.brown[800]),
          ),
        );
      case 9:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Text('Done', style: TextStyle(color: Colors.green[800])),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Text('Not Error', style: TextStyle(color: Colors.red[800])),
        );
    }
  }

  Widget _getDanhGiaView(String? status) {
    switch (status) {
      case 'OK':
        return Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text(
              'OK',
              style: TextStyle(
                fontSize: Common.sizeColumn,
                color: Colors.green,
              ),
            ),
          ],
        );
      case 'NG':
        return Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 16),
            SizedBox(width: 4),
            Text(
              'NG',
              style: TextStyle(fontSize: Common.sizeColumn, color: Colors.red),
            ),
          ],
        );
      case 'Stop Working':
        return Row(
          children: [
            Icon(Icons.pause_circle, color: Colors.orange, size: 16),
            SizedBox(width: 4),
            Text(
              'Stop Working',
              style: TextStyle(
                fontSize: Common.sizeColumn,
                color: Colors.orange,
              ),
            ),
          ],
        );
      case 'Finish L/C':
        return Row(
          children: [
            Icon(Icons.done_all, color: Colors.blue, size: 16),
            SizedBox(width: 4),
            Text(
              'Finish L/C',
              style: TextStyle(fontSize: Common.sizeColumn, color: Colors.blue),
            ),
          ],
        );
      default:
        return Row();
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => controller.filterdataList.length;

  @override
  int get selectedRowCount => 0;
}
