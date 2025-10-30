import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/Approval_Contract_Controller.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class ApprovalPrepartionScreen extends StatefulWidget {
  const ApprovalPrepartionScreen({super.key});

  @override
  State<ApprovalPrepartionScreen> createState() =>
      _ApprovalPrepartionScreenState();
}

class _ApprovalPrepartionScreenState extends State<ApprovalPrepartionScreen> {
  final DashboardControllerApporver controller = Get.put(
    DashboardControllerApporver(),
  );
  final ScrollController _scrollController = ScrollController();
  // Controller nội bộ cho phân trang tùy chỉnh (theo dõi chỉ số trang thủ công)
  // Không dùng PaginatorController vì PaginatedDataTable2 phiên bản hiện tại không hỗ trợ tham số này.
  int _rowsPerPage = 100;
  int _firstRowIndex = 0; // track first row of current page
  final List<int> _availableRowsPerPage = const [100, 150, 200, 250];
  //RxString selectedContractType  = RxString('');
  String get _indefiniteContractText => tr('indefiniteContract');
  String get _trialContractText => tr('trialContract');
  // Mặc định chuyển sang trialContract
  String TypeValue = tr('trialContract');
  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
    // Lấy dữ liệu mặc định theo trialContract (apprentice)
    controller.fetchData(
      contractType: 'apprentice',
      statusId: '2',
      section: null,
      adid: authState.user?.chRUserid ?? '',
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
    final authState = Provider.of<AuthState>(context, listen: true);
    final controller = Get.find<DashboardControllerApporver>();

    // Extract section name safely
    // String sectionName =
    //     authState.user?.chRSecCode?.toString().split(':').last.trim() ?? '';
    return Obx(() {
      final currentValue = controller.currentContractType.value == 'two'
          ? _indefiniteContractText
          : controller.currentContractType.value == 'apprentice'
          ? _trialContractText
          : _trialContractText; // Giá trị mặc định sửa thành trial
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 20),
          Text(
            tr('TypeContract'),
            style: TextStyle(
              color: Common.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: Common.sizeColumn,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                hint: Text(tr('indefiniteContract')),
                icon: Icon(Icons.arrow_drop_down, color: Common.primaryColor),
                style: TextStyle(
                  fontSize: Common.sizeColumn,
                  color: Colors.black87,
                ),
                onChanged: (newValue) {
                  if (newValue != null) {
                    // Map the translated value to controller contract type
                    final contractType = newValue == tr('indefiniteContract')
                        ? 'two'
                        : 'apprentice';
                    TypeValue = newValue;
                    controller.setContractType(contractType);
                    controller.fetchData(
                      contractType: contractType,
                      statusId: '2',
                      section: null,
                      adid: authState.user?.chRUserid ?? '',
                    );
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: tr('indefiniteContract'),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          tr('indefiniteContract'),
                          style: TextStyle(
                            fontSize: Common.sizeColumn,
                            color: Common.greenColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: tr('trialContract'),
                    child: Row(
                      children: [
                        Icon(Icons.work_outline, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          tr('trialContract'),
                          style: TextStyle(
                            fontSize: Common.sizeColumn,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 30),
          // Send button
          GestureDetector(
            onTap: () async {
              try {
                await controller.updateListContractApproval(
                  authState.user!.chRUserid.toString(),
                  authState.user!.chRUserid.toString(),
                  controller.currentContractType.value,
                );
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
                          tr('Confirm'),
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
          tr('preparationApproval'),
          style: TextStyle(
            color: Common.primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('Approverhint'),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSearchAndActions() {
    final authState = Provider.of<AuthState>(context, listen: true);
    final contractType = TypeValue == tr('indefiniteContract')
        ? 'two'
        : 'apprentice';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final bool isSmall = maxW < 900; // tablet / small desktop
        final bool isXSmall = maxW < 600; // narrow mobile

        double fw(double desired) {
          if (isXSmall) return maxW - 40; // full width on very small
          if (isSmall) return desired.clamp(110, 240);
          return desired;
        }

        final widgets = <Widget>[
          if (!isXSmall)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
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
            icon: Iconsax.back_square,
            color: Colors.orange,
            tooltip: tr('ReturnS'),
            onPressed: () => _ReturnSDialog(
              authState.user!.chRUserid.toString(),
              contractType,
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
                    ...widgets.map(
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
                  children: widgets,
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

  void _ReturnSDialog(String adid, String typeContract) {
    final controller = Get.find<DashboardControllerApporver>();
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
                  typeContract,
                );
                controller.fetchData(
                  contractType: typeContract,
                  statusId: '2',
                  section: null,
                  adid: adid,
                );
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
                    width: 2180, //2570,
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
                              // DataColumnCustom(
                              //   title: tr('paidLeave'),
                              //   width: 100,
                              //   maxLines: 2,
                              //   fontSize: Common.sizeColumn,
                              // ).toDataColumn2(),
                              // DataColumnCustom(
                              //   title: tr('unpaidLeave'),
                              //   width: 90,
                              //   maxLines: 2,
                              //   fontSize: Common.sizeColumn,
                              // ).toDataColumn2(),
                              // DataColumnCustom(
                              //   title: tr('unreportedLeave'),
                              //   width: 90,
                              //   maxLines: 2,
                              //   fontSize: Common.sizeColumn,
                              // ).toDataColumn2(),
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
                                title: tr('Apporval'), //tr('notRehirable'),
                                width: 170,
                                maxLines: 2,
                                fontSize: Common.sizeColumn,
                              ).toDataColumn2(),
                              DataColumnCustom(
                                title: tr(
                                  'LydoTuChoi',
                                ), //tr('notRehirableReason'),
                                width: 170,
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
}

class MyData extends DataTableSource {
  final DashboardControllerApporver controller = Get.find();
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
      text: data.nvchRApproverPer ?? "",
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
              fontSize: Common.sizeColumn,
            ),
          ),
        ),
        // Copyable vchRCodeApprover
        DataCell(_buildCopyCell(data.vchRCodeApprover ?? "")),
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
              data.inTViolation?.toString() ?? "",
              style: TextStyle(fontSize: Common.sizeColumn),
            ),
          ),
        ),
        DataCell(
          Text(
            data.nvarchaRViolation?.toString() ?? "",
            style: TextStyle(fontSize: Common.sizeColumn),
          ),
        ),
        // thuộc tính approver
        DataCell(
          Obx(() {
            Visibility(
              visible: false,
              child: Text(controller.filterdataList[index].toString()),
            );
            final rawStatus =
                controller.filterdataList[index].biTApproverPer ?? true;
            final status = rawStatus ? 'OK' : 'NG';
            return DropdownButton<String>(
              value: status,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.updateApproval(
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
                controller.updateNoteApprovel(
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
              // onChanged: (value) {
              //   controller.updateNoteApprovel(
              //     data.vchREmployeeId.toString(),
              //     value,
              //   );
              // },
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => controller.filterdataList.length;

  @override
  int get selectedRowCount => 0;
}
