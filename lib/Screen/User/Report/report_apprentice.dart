import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/Apprentice_Contract_controller.dart';
import 'package:web_labor_contract/API/Controller/PTHC_controller.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/custom_field.dart';
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

class ReportApprentice extends StatefulWidget {
  const ReportApprentice({super.key});

  @override
  State<ReportApprentice> createState() => _ReportApprenticeState();
}

class _ReportApprenticeState extends State<ReportApprentice> {
  final DashboardControllerApprentice controller = Get.put(
    DashboardControllerApprentice(),
  );
  final DashboardControllerPTHC controllerPTHC = Get.put(
    DashboardControllerPTHC(),
  );
  final ScrollController _scrollController = ScrollController();
  // Controller nội bộ cho phân trang tùy chỉnh (theo dõi chỉ số trang thủ công)
  // Không dùng PaginatorController vì PaginatedDataTable2 phiên bản hiện tại không hỗ trợ tham số này.
  int _rowsPerPage = 50;
  int _firstRowIndex = 0; // track first row of current page
  final List<int> _availableRowsPerPage = const [50, 100, 150, 200];
  bool _statusInitialized = false; // tránh gọi lại nhiều lần
  @override
  void initState() {
    super.initState();
    // Load initial data once
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = Provider.of<AuthState>(context, listen: false);
      // Làm mới các dữ liệu tìm kiếm ban đầu (chỉ 1 lần)
      controller.refreshSearch();
      controller.fetchSectionList();
      await _prepareStatus(authState);
    });
  }
  Future <void> _prepareStatus(AuthState authState) async {
    if (_statusInitialized) return;
    try {
      // Bắt buộc phải tải listPTHCsection trước khi so sánh
      await controllerPTHC.fetchPTHCSectionList(
        authState.user!.chREmployeeId.toString(),
      );
      String sectionName = authState.user!.chRSecCode
          .toString()
          .split(':')[1]
          .trim();
    if (authState.user!.chRGroup.toString() == "PTHC") {
      if (controllerPTHC.listPTHCsection.isNotEmpty) {
        sectionName =
            '[${controllerPTHC.listPTHCsection.map((e) => '"$e"').join(',')}]';
      } else {
        sectionName = authState.user!.chRSecCode
            .toString()
            .split(':')[1]
            .trim();
      }
      // truong hop PTHC phong ban
      controller.fetchDummyData(sectionName);
    } else {
      controller.fetchDummyData(null);
    }
      _statusInitialized = true;
    } catch (e) {
      // Có thể log hoặc hiển thị lỗi nếu cần
      debugPrint('Prepare status error: $e');
    }
  }
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
            // _buildApproverPer(),
            // const SizedBox(height: 10),

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
          '${tr('report')} ${tr('trialContract')}',
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
    final DashboardControllerApprentice controller = Get.find();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final bool isSmall = maxW < 900; // tablet / small desktop
        final bool isXSmall = maxW < 600; // mobile width

        double fw(double desired) {
          if (isXSmall) return maxW - 40; // full width minus padding
          if (isSmall) return desired.clamp(120, 220);
          return desired; // large screen keep original
        }

        final statusOptions = <Map<String, dynamic>>[
          {'code': 'all', 'label': 'all'},
          {'code': 'New', 'label': 'New'},
          {'code': 'Per', 'label': 'Per/人事課の中級管理職'},
          {'code': 'PTHC', 'label': 'PTHC'},
          {'code': 'Leader', 'label': 'Leader'},
          {'code': 'Chief', 'label': 'Chief'},
          {'code': 'QLTC', 'label': 'QLTC/中級管理職'},
          {'code': 'QLCC', 'label': 'QLCC/上級管理職'},
          {'code': 'Director', 'label': 'Director/管掌取締役'},
          {'code': 'Done', 'label': 'Done'},
          {'code': 'Not Done', 'label': 'Not Done'},
        ];

        Widget statusDropdown = SizedBox(
          width: fw(220),
          child: Obx(
            () => DropdownButtonFormField<String>(
              value: controller.selectedStatus.value.isEmpty
                  ? null
                  : controller.selectedStatus.value,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: tr('status'),
                hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                prefixIcon: Icon(
                  Iconsax.activity,
                  size: 20,
                  color: Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.black54,
                    width: .5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5),
                ),
                isDense: true,
              ),
              isExpanded: true,
              hint: Text(
                tr('status'),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              items: statusOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['code'] as String,
                  child: Text(
                    option['label'] as String,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                controller.updateStatus(value);
              },
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 20,
              ),
              menuMaxHeight: 320,
            ),
          ),
        );

        final filters = <Widget>[
          // Tiêu đề (ẩn trên màn nhỏ để tiết kiệm không gian)
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
          statusDropdown,
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
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 6,
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
                    ...filters.map(
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
                  children: filters,
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
    final authState = Provider.of<AuthState>(context, listen: true);
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
                    width: 4870, //2570,
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
                              if (authState.user?.chRGroup != 'PTHC')
                                DataColumnCustom(
                                  title: tr('action'),
                                  width: 100,
                                  fontSize: Common.sizeColumn,
                                ).toDataColumn2(),
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
                              // các trường thông tin phê duyệt
                              DataColumnCustom(
                                title: tr('Nguoilap'),
                                width: 100,
                                maxLines: 2,
                                fontSize: Common.sizeColumn,
                              ).toDataColumn2(),
                              DataColumnCustom(
                                title: tr('Nhansu'),
                                width: 150,
                                maxLines: 2,
                                fontSize: Common.sizeColumn,
                              ).toDataColumn2(),
                              DataColumnCustom(
                                title: tr('NguoiDanhgia'),
                                width: 150,
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
                                title: tr('TruongPhong'),
                                width: 150,
                                maxLines: 2,
                                fontSize: Common.sizeColumn,
                              ).toDataColumn2(),
                              DataColumnCustom(
                                title: tr('QuanLyCC'),
                                width: 150,
                                maxLines: 2,
                                fontSize: Common.sizeColumn,
                              ).toDataColumn2(),
                            ],
                            rows: List.generate(
                              visibleCount,
                              (i) => dataSource.getRow(_firstRowIndex + i)!,
                            ),
                          ),
                        );
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
    String getStatusLabel(int? IntStatus) {
      switch (IntStatus) {
        case 1:
          return 'New';
        case 2:
          return 'Per/人事課の中級管理職';
        case 3:
          return 'PTHC';
        case 4:
          return 'Leader';
        case 5:
          return 'Chief';
        case 6:
          return 'QLTC/中級管理職';
        case 7:
          return 'QLCC/上級管理職';
        case 8:
          return 'Director/管掌取締役';
        case 9:
          return 'Done';
        default:
          return 'Not Error';
      }
    }

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
                  'assets/templates/MauTV.xlsx',
                );
                final excel = Excel.decodeBytes(
                  templateData.buffer.asUint8List(),
                );
                final sheet =
                    excel['Sheet1']; //?? excel[excel.tables.keys.first];
                const startRow = 15; // Dòng bắt đầu điền dữ liệu
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
                  setCellValue('B', getStatusLabel(item.inTStatusId));
                  setCellValue('C', item.vchRCodeApprover ?? '');
                  setCellValue('D', item.vchREmployeeId ?? '');
                  setCellValue('E', item.vchRTyperId ?? '');
                  setCellValue('F', item.vchREmployeeName ?? '');
                  setCellValue('G', item.vchRNameSection ?? '');
                  setCellValue('H', item.chRCostCenterName ?? '');
                  setCellValue('I', getAgeFromBirthday(item.dtMBrithday));
                  setCellValue('J', item.chRPosition ?? '');
                  setCellValue('K', item.chRCodeGrade ?? '');
                  if (item.dtMJoinDate != null) {
                    setCellValue(
                      'L',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(item.dtMJoinDate!)),
                    );
                  }
                  if (item.dtMEndDate != null) {
                    setCellValue(
                      'M',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(item.dtMEndDate!)),
                    );
                  }
                  setCellValue('N', item.fLGoLeaveLate ?? '0');
                  setCellValue('O', item.fLNotLeaveDay ?? '0');
                  setCellValue('P', item.inTViolation ?? '0');
                  setCellValue(
                    'Q',
                    item.inTStatusId == 3 ? "" : (item.vchRLyThuyet ?? ''),
                  );
                  setCellValue(
                    'R',
                    item.inTStatusId == 3 ? "" : (item.vchRThucHanh ?? ''),
                  );
                  setCellValue(
                    'S',
                    item.inTStatusId == 3 ? "" : (item.vchRCompleteWork ?? ''),
                  );
                  setCellValue(
                    'T',
                    item.inTStatusId == 3 ? "" : (item.vchRLearnWork ?? ''),
                  );
                  setCellValue(
                    'U',
                    item.inTStatusId == 3 ? "" : (item.vchRThichNghi ?? ''),
                  );
                  setCellValue(
                    'V',
                    item.inTStatusId == 3 ? "" : (item.vchRUseful ?? ''),
                  );
                  setCellValue(
                    'W',
                    item.inTStatusId == 3 ? "" : (item.vchRContact ?? ''),
                  );
                  setCellValue(
                    'X',
                    item.inTStatusId == 3 ? "" : (item.vcHNeedViolation ?? ''),
                  );
                  setCellValue(
                    'Y',
                    item.inTStatusId == 3
                        ? ""
                        : (item.vchRReasultsLeader ?? ''),
                  );
                  setCellValue(
                    'Z',
                    item.inTStatusId == 3 ? "" : (item.vchRNote ?? ''),
                  );
                  setCellValue(
                    'AA',
                    item.biTNoReEmployment == null
                        ? ""
                        : (item.biTNoReEmployment ? "" : "X"),
                  );
                  setCellValue(
                    'AB',
                    item.inTStatusId == 3
                        ? ""
                        : (item.nvchRNoReEmpoyment ?? ''),
                  );
                  setCellValue('AC', item.vchRUserCreate ?? '');
                  setCellValue('AD', item.useRApproverPer ?? '');
                  setCellValue('AE', item.vchRLeaderEvalution ?? '');
                  setCellValue('AF', item.useRApproverChief ?? '');
                  setCellValue('AG', item.useRApproverSectionManager ?? '');
                  setCellValue('AH', item.userApproverDeft ?? '');
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
        6 => data.nvchRApproverChief ?? '',
        7 => data.nvchRApproverManager ?? '',
        _ => '',
      },
    );
    final authState = Provider.of<AuthState>(context, listen: true);
    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (index.isEven) return Colors.grey[50];
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
              fontSize: Common.sizeColumn,
            ),
          ),
        ),
        // Action
        if (authState.user?.chRGroup != 'PTHC')
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
                        builder: (context) =>
                            _EditContractDialog(contract: data),
                      );
                    },
                  ),
                  SizedBox(width: 3),
                  _buildActionButton(
                    icon: Iconsax.clock,
                    color: Colors.orangeAccent,
                    onPressed: () {
                      if (data.dtMDueDate != null) {
                        showDialog(
                          context: context,
                          builder: (context) => _UpdateDtmDue(contract: data),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => DialogNotification(
                            message: tr('TimeDueError'),
                            title: tr('Loi'),
                            color: Colors.red,
                            icon: Icons.error,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(width: 3),
                  if (authState.user?.chRGroup == 'Admin' ||
                      authState.user?.chRGroup == 'Chief Per')
                    _buildActionButton(
                      icon: Iconsax.ram,
                      color: Colors.brown,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _UpdateKetQua(contract: data),
                        );
                      },
                    ),
                  const SizedBox(width: 3),
                  if (authState.user?.chRGroup == 'Admin' ||
                      authState.user?.chRGroup == 'Chief Per')
                    _buildActionButton(
                      icon: Iconsax.back_square,
                      color: Colors.red,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _ReturnContract(contract: data),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
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
        // Đánh giá
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
        DataCell(
          Text(
            data.vchRNote?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Obx(() {
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final rawStatus =
                controller.filterdataList[index].biTNoReEmployment;
            String status = rawStatus ? "OK" : "NG";
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
        // Phê duyệt
        DataCell(
          Text(
            data.vchRUserCreate?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.useRApproverPer?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.vchRLeaderEvalution?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.useRApproverChief?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.useRApproverSectionManager ?? '',
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        DataCell(
          Text(
            data.userApproverDeft?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
      ],
    );
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
          child: Text('Per', style: TextStyle(color: Colors.purple[800])),
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
          child: Text(
            'Chief',
            style: TextStyle(color: const Color.fromARGB(255, 192, 21, 192)),
          ),
        );
      case 6:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.yellow[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.yellow[100]!),
          ),
          child: Text('Manager', style: TextStyle(color: Colors.yellow[800])),
        );
      case 7:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal[100]!),
          ),
          child: Text('Dept', style: TextStyle(color: Colors.teal[800])),
        );
      case 8:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown[100]!),
          ),
          child: Text('Director', style: TextStyle(color: Colors.brown[800])),
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

// Edit thông tin hợp đồng
class _EditContractDialog extends StatelessWidget {
  final ApprenticeContract contract;
  final DashboardControllerApprentice controller = Get.find();
  final DashboardControllerPTHC controllerPTHC = Get.find();

  _EditContractDialog({required this.contract});

  @override
  Widget build(BuildContext context) {
    final edited = ApprenticeContract.fromJson(contract.toJson());
    RxString errorMessage = ''.obs;
    final authState = Provider.of<AuthState>(context, listen: true);

    final RxString earlyLateError = ''.obs;
    final RxString unreportedLeaveError = ''.obs;
    final RxString violationError = ''.obs;
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
                  // Expanded(
                  //   child: BuildCompactTextField(
                  //     initialValue: contract.vchRCodeSection,
                  //     label: tr('department'),
                  //     onChanged: (value) => edited.vchRCodeSection = value,
                  //   ),
                  // ),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: (() {
                        final target = (edited.vchRNameSection ?? '')
                            .replaceAll(RegExp(r'\s+'), '')
                            .toLowerCase();
                        for (final s in controller.listSection) {
                          if (s.replaceAll(RegExp(r'\s+'), '').toLowerCase() ==
                              target) {
                            return s; // return original value in listSection
                          }
                        }
                        return null;
                      })(),
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
                              child: Text(
                                section,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        edited.vchRNameSection = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildCompactTextField(
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
                    child: _buildCompactReadOnlyField(
                      value: contract.vchREmployeeId.toString(),
                      label: tr('employeeCode'),
                      width: 400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildCompactReadOnlyField(
                      value: contract.vchRTyperId.toString(),
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
                      value: contract.vchREmployeeName.toString(),
                      label: tr('fullName'),
                      width: 420,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: _buildCompactReadOnlyField(
                      value: getAgeFromBirthday(
                        contract.dtMBrithday,
                      ).toString(),
                      label: tr('age'),
                      width: 80,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10, width: 500),

              // Dòng 4: Vị trí + Bậc lương
              Row(
                children: [
                  Expanded(
                    child: _buildCompactReadOnlyField(
                      value: contract.chRPosition.toString(),
                      label: tr('position'),
                      width: 400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildCompactReadOnlyField(
                      value: contract.chRCodeGrade.toString(),
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
                      ).format(DateTime.parse(contract.dtMJoinDate!)),
                      label: tr('contractEffective'),
                      width: 250,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactReadOnlyField(
                      value: DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(contract.dtMEndDate!)),
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
                            initialValue: contract.fLGoLeaveLate?.toString(),
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
                            initialValue: contract.fLNotLeaveDay?.toString(),
                            label: tr('unreportedLeave'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value.isEmpty) {
                                unreportedLeaveError.value = '';
                                edited.fLNotLeaveDay = null;
                                return;
                              }
                              if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                                unreportedLeaveError.value = tr('onlyNumber');
                              } else {
                                unreportedLeaveError.value = '';
                                edited.fLNotLeaveDay = double.tryParse(value);
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
              // Dòng 8: Số lần vi phạm
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BuildCompactTextField(
                            initialValue: contract.inTViolation?.toString(),
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
              const SizedBox(height: 12),

              // Lý do vi phạm (chiếm full width)
              BuildCompactTextField(
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
                      String sectionName = '';
                      // reset du lieu
                      if (authState.user!.chRGroup.toString() == "PTHC") {
                        if (controllerPTHC.listPTHCsection.isNotEmpty) {
                          sectionName =
                              '[${controllerPTHC.listPTHCsection.map((e) => '"$e"').join(',')}]';
                        } else {
                          sectionName = authState.user!.chRSecCode
                              .toString()
                              .split(':')[1]
                              .trim();
                        }
                        // truong hop PTHC phong ban
                        controller.fetchDummyData(sectionName);
                      } else {
                        controller.fetchDummyData(null);
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

// Update gia hạn thời gian
class _UpdateDtmDue extends StatelessWidget {
  final ApprenticeContract contract;
  final DashboardControllerApprentice controller = Get.find();
  final DashboardControllerPTHC controllerPTHC = Get.find();

  _UpdateDtmDue({required this.contract});

  @override
  Widget build(BuildContext context) {
    final edited = ApprenticeContract.fromJson(contract.toJson());
    RxString errorMessage = ''.obs;
    final authState = Provider.of<AuthState>(context, listen: true);
    DateTime? selectedDate;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Icon(Iconsax.lamp1, color: Common.primaryColor),
          const SizedBox(width: 10),
          Text(
            tr("GiaHan"),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Common.blackColor,
            ),
          ),
          Text(
            ' ${contract.vchREmployeeName}',
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
              // Hiển thị ngày hết hạn hiện tại
              if (contract.dtMDueDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    tr("NgayHetHan") +
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.parse(edited.dtMDueDate!)),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Date picker để chọn ngày mới
              _buildDatePickerField(
                context: context,
                initialDate: contract.dtMDueDate != null
                    ? DateFormat('yyyy-MM-dd').parse(contract.dtMDueDate!)
                    : DateTime.now().add(const Duration(days: 30)),
                label: tr("NgayMoi"),
                onDateSelected: (date) {
                  selectedDate = date;
                  edited.dtMDueDate = DateFormat('yyyy-MM-dd').format(date);
                },
              ),

              // Hiển thị thông báo lỗi
              Obx(
                () => errorMessage.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          errorMessage.value,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      )
                    : const SizedBox(),
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

                    // Kiểm tra nếu ngày mới không được chọn
                    if (selectedDate == null) {
                      errorMessage.value = tr('ChonNgay');
                      return;
                    }

                    // Kiểm tra nếu ngày mới không sau ngày hiện tại
                    if (selectedDate!.isBefore(DateTime.now())) {
                      errorMessage.value = tr('NgayChonSai');
                      return;
                    }
                    controller.isLoading(true);
                    try {
                      await controller.updateApprenticeContract(
                        edited,
                        authState.user!.chRUserid.toString(),
                      );

                      String sectionName = '';
                      // reset du lieu
                      if (authState.user!.chRGroup.toString() == "PTHC") {
                        if (controllerPTHC.listPTHCsection.isNotEmpty) {
                          sectionName =
                              '[${controllerPTHC.listPTHCsection.map((e) => '"$e"').join(',')}]';
                        } else {
                          sectionName = authState.user!.chRSecCode
                              .toString()
                              .split(':')[1]
                              .trim();
                        }
                        // truong hop PTHC phong ban
                        controller.fetchDummyData(sectionName);
                      } else {
                        await controller.fetchDummyData(null);
                      }
                      // await controller.fetchDummyData();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        // Hiển thị thông báo thành công
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('GiaHanSusses')),
                            backgroundColor: Colors.green,
                          ),
                        );
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

  Widget _buildDatePickerField({
    required BuildContext context,
    required DateTime initialDate,
    required String label,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Common.primaryColor,
                      onPrimary: Colors.white,
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
            if (picked != null && picked != initialDate) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(initialDate),
                  style: const TextStyle(fontSize: 14),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Common.primaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// update kết quả đánh giá cuối cùng
class _UpdateKetQua extends StatelessWidget {
  final ApprenticeContract contract;
  final DashboardControllerApprentice controller = Get.find();
  final DashboardControllerPTHC controllerPTHC = Get.find();

  _UpdateKetQua({required this.contract});

  @override
  Widget build(BuildContext context) {
    final edited = ApprenticeContract.fromJson(contract.toJson());
    final errorMessage = ''.obs;
    final reson = ''.obs;
    final ketquaOld = (edited.vchRReasultsLeader ?? 'OK').obs;
    final authState = Provider.of<AuthState>(context, listen: false);
    final selectedStatus = (edited.vchRReasultsLeader ?? 'OK').obs;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Icon(Iconsax.lamp1, color: Common.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Text(
                  "${tr("SuaKetQuaCC")} ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Common.blackColor,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "${contract.vchREmployeeName ?? ""} ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Common.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Row(
                children: [
                  Text(
                    "${tr("ketqua")} ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Common.blackColor,
                    ),
                  ),
                  Obx(
                    () => DropdownButton<String>(
                      value: selectedStatus.value,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          selectedStatus.value = newValue;
                          edited.vchRReasultsLeader = newValue;
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'OK',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: Common.sizeColumn,
                                  color: _getStatusColor(selectedStatus.value),
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
                              const SizedBox(width: 4),
                              Text(
                                'NG',
                                style: TextStyle(
                                  fontSize: Common.sizeColumn,
                                  color: _getStatusColor(selectedStatus.value),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Stop Working',
                          child: Row(
                            children: [
                              Icon(
                                Icons.pause_circle,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stop Working',
                                style: TextStyle(
                                  fontSize: Common.sizeColumn,
                                  color: _getStatusColor(selectedStatus.value),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Finish L/C',
                          child: Row(
                            children: [
                              Icon(
                                Icons.done_all,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Finish L/C',
                                style: TextStyle(
                                  fontSize: Common.sizeColumn,
                                  color: _getStatusColor(selectedStatus.value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _buildCompactTextField(
                    initialValue: reson.value,
                    label: tr('reason'),
                    onChanged: (value) => reson.value = value,
                    maxLines: 2,
                  ),
                ],
              ),
            ],
          ),

          // Hiển thị thông báo lỗi
          Obx(
            () => errorMessage.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      errorMessage.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
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
                    try {
                      if (reson.value.isEmpty) {
                        errorMessage.value = tr('pleaseReason');
                        controller.isLoading(false);
                        return;
                      }
                      // Cập nhật giá trị từ selectedStatus
                      edited.vchRReasultsLeader = selectedStatus.value;
                      if (selectedStatus.value != 'OK') {
                        edited.biTNoReEmployment = false;
                        //edited.nvchRApproverManager = 'Thay đổi từ sửa kết quả đánh giá cuối cùng';
                      }
                      edited.vchRNote = reson.value;
                      await controller.updateKetQuaApprenticeContract(
                        edited,
                        authState.user!.chRUserid.toString(),
                        ketquaOld.value,
                      );

                      // Refresh dữ liệu
                      String sectionName = '';
                      if (authState.user!.chRGroup.toString() == "PTHC") {
                        if (controllerPTHC.listPTHCsection.isNotEmpty) {
                          sectionName =
                              '[${controllerPTHC.listPTHCsection.map((e) => '"$e"').join(',')}]';
                        } else {
                          sectionName = authState.user!.chRSecCode
                              .toString()
                              .split(':')[1]
                              .trim();
                        }
                        // truong hop PTHC phong ban
                        controller.fetchDummyData(sectionName);
                      } else {
                        await controller.fetchDummyData(null);
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        // Hiển thị thông báo thành công
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('DonteCC')),
                            backgroundColor: Colors.green,
                          ),
                        );
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

// Trả lại các bước
class _ReturnContract extends StatelessWidget {
  final ApprenticeContract contract;
  final DashboardControllerApprentice controller = Get.find();
  final DashboardControllerPTHC controllerPTHC = Get.find();
  _ReturnContract({required this.contract});

  @override
  Widget build(BuildContext context) {
    final edited = ApprenticeContract.fromJson(contract.toJson());
    RxString errorMessage = ''.obs;
    RxInt intStatus = 0.obs;
    final authState = Provider.of<AuthState>(context, listen: true);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Icon(Iconsax.back_square, color: Colors.red),
          SizedBox(width: 10),
          Text(
            tr('reject'),
            style: TextStyle(
              color: Common.grayColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 6),
          Text(
            edited.vchREmployeeName ?? "",
            style: TextStyle(
              color: Common.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Danh sách lựa chọn trả về
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('ChonTraVe'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Common.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Column(
                  children: [
                    RadioListTile<int>(
                      value: 1,
                      groupValue: intStatus.value,
                      title: Text(tr('TraVePER')),
                      onChanged: (value) {
                        intStatus.value = value!;
                        edited.inTStatusId = value;
                      },
                      activeColor: Common.primaryColor,
                    ),
                    RadioListTile<int>(
                      value: 3,
                      groupValue: intStatus.value,
                      title: Text(tr('TraVePTHC')),
                      onChanged: (value) {
                        intStatus.value = value!;
                        edited.inTStatusId = value;
                      },
                      activeColor: Common.primaryColor,
                    ),
                    RadioListTile<int>(
                      value: 4,
                      groupValue: intStatus.value,
                      title: Text(tr('TraVeNguoiDanhGia')),
                      onChanged: (value) {
                        intStatus.value = value!;
                        edited.inTStatusId = value;
                      },
                      activeColor: Common.primaryColor,
                    ),
                  ],
                ),
              ),
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
                      await controller.updateApprenticeContract(
                        edited,
                        authState.user!.chRUserid.toString(),
                      );
                      await controller.sendEmailReturn(
                        edited,
                        authState.user!.chRUserid.toString(),
                        "Trả về từ báo cáo của nhân sự",
                      );
                      // Refresh dữ liệu
                      String sectionName = '';
                      // reset du lieu
                      if (authState.user!.chRGroup.toString() == "PTHC") {
                        if (controllerPTHC.listPTHCsection.isNotEmpty) {
                          sectionName =
                              '[${controllerPTHC.listPTHCsection.map((e) => '"$e"').join(',')}]';
                        } else {
                          sectionName = authState.user!.chRSecCode
                              .toString()
                              .split(':')[1]
                              .trim();
                        }
                        // truong hop PTHC phong ban
                        controller.fetchDummyData(sectionName);
                      } else {
                        await controller.fetchDummyData(null);
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        // Hiển thị thông báo thành công
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('ResultOk')),
                            backgroundColor: Colors.green,
                          ),
                        );
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
}
