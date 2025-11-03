import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:web_labor_contract/API/Controller/Apprentice_Contract_controller.dart';
import 'package:web_labor_contract/API/Controller/PTHC_controller.dart';
import 'package:web_labor_contract/API/Controller/user_approver_controller.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/action_button.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/data_column_custom.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
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
  final DashboardControllerPTHC controllerPTHC = Get.put(
    DashboardControllerPTHC(),
  );
  final DashboardControllerUserApprover controllerUserApprover = Get.put(
    DashboardControllerUserApprover(),
  );
  final ScrollController _scrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  // Controller nội bộ cho phân trang tùy chỉnh (theo dõi chỉ số trang thủ công)
  // Không dùng PaginatorController vì PaginatedDataTable2 phiên bản hiện tại không hỗ trợ tham số này.
  int _rowsPerPage = 50;
  int _firstRowIndex = 0; // track first row of current page
  final List<int> _availableRowsPerPage = const [50, 100, 150, 200];
  bool _statusInitialized = false; // tránh gọi lại nhiều lần

  @override
  void initState() {
    super.initState();
    // Di chuyển các lời gọi mạng khỏi build để tránh lặp lại không cần thiết
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = Provider.of<AuthState>(context, listen: false);
      // Làm mới các dữ liệu tìm kiếm ban đầu (chỉ 1 lần)
      controller.refreshSearch();
      controller.fetchPTHCData();
      await controller.fetchSectionList();
      await _prepareStatus(authState);
    });

    // Đồng bộ cuộn dọc giữa bảng cố định và bảng cuộn
    _leftVerticalController.addListener(() {
      if (_rightVerticalController.hasClients &&
          _rightVerticalController.offset != _leftVerticalController.offset) {
        _rightVerticalController.jumpTo(_leftVerticalController.offset);
      }
    });
    _rightVerticalController.addListener(() {
      if (_leftVerticalController.hasClients &&
          _leftVerticalController.offset != _rightVerticalController.offset) {
        _leftVerticalController.jumpTo(_rightVerticalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    _scrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  Future<void> _prepareStatus(AuthState authState) async {
    if (_statusInitialized) return;
    try {
      // Bắt buộc phải tải listPTHCsection trước khi so sánh
      await controllerPTHC.fetchPTHCSectionList(
        authState.user!.chREmployeeId.toString(),
      );
      final parts = authState.user!.chRSecCode?.toString().split(':') ?? [];
      String sectionName = parts.length >= 2
          ? '${parts[0].trim()} : ${parts[1].trim()}'
          : parts.firstOrNull?.trim() ?? '';
      if (authState.user!.chRGroup.toString() == "PTHC" ||
          authState.user!.chRGroup.toString() == "Per" ||
          authState.user!.chRGroup.toString() == "Admin") {
        if (authState.user!.chRGroup.toString() == "PTHC") {
          sectionName = '';
          if (controllerPTHC.listPTHCsection.isNotEmpty) {
            sectionName =
                '[${controllerPTHC.listPTHCsection.map((e) => '"$e"').join(',')}]';
          } else {
            sectionName = parts.length >= 2
                ? '${parts[0].trim()} : ${parts[1].trim()}'
                : parts.firstOrNull?.trim() ?? '';
          }
          // truong hop PTHC phong ban
          controller.changeStatus(
            'PTHC',
            sectionName,
            authState.user!.chRUserid.toString(),
            null,
          );
        } else {
          // truong hop khác
          controller.changeStatus('PTHC', null, null, null);
        }
        controllerUserApprover.changeStatus(
          sectionName,
          'Technician,Leader,Supervisor,Operator,Staff,Section Manager,Expert,Chief',
        );
      } else if (authState.user!.chRGroup.toString() == "Chief" ||
          authState.user!.chRGroup.toString() == "Expert") {
        controller.changeStatus(
          '5',
          sectionName,
          authState.user!.chRUserid.toString(),
          null,
        );
        controllerUserApprover.changeStatus(sectionName, 'Section Manager');
      } else {
        // truong hop leader
        controller.changeStatus(
          '4',
          sectionName,
          authState.user!.chRUserid.toString(),
          null,
        );
        // truong hop leader
        controllerUserApprover.changeStatus(sectionName, 'Chief,Expert');
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
            // Header + Search + Note (responsive combined layout)
            _buildHeaderSearchWithNote(),
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
                    Positioned.fill(child: _buildFrozenDataTable()),
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
    final parts = authState.user!.chRSecCode?.toString().split(':') ?? [];
    String sectionName = parts.length >= 2
        ? '${parts[0].trim()} : ${parts[1].trim()}'
        : parts.firstOrNull?.trim() ?? '';
    final controller = Get.put(DashboardControllerUserApprover());
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
                  authState.user!.chRGroup.toString(),
                );
                if (authState.user!.chRGroup.toString() == "PTHC" ||
                    authState.user!.chRGroup.toString() == "Per" ||
                    authState.user!.chRGroup.toString() == "Admin") {
                  // truong hop PTHC phong ban

                  await controllerTwo.changeStatus(
                    'PTHC',
                    sectionName,
                    authState.user!.chRUserid.toString(),
                    null,
                  );
                } else if (authState.user!.chRGroup.toString() == "Chief" ||
                    authState.user!.chRGroup.toString() == "Expert") {
                  await controllerTwo.changeStatus(
                    '5',
                    sectionName,
                    authState.user!.chRUserid.toString(),
                    null,
                  );
                } else {
                  // truong hop leader
                  await controllerTwo.changeStatus(
                    '4',
                    sectionName,
                    authState.user!.chRUserid.toString(),
                    null,
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
    final authState = Provider.of<AuthState>(context, listen: true);
    String sectionName = authState.user!.chRSecCode
        .toString()
        .split(':')[1]
        .trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final bool isSmall = maxW < 900; // small desktop / tablet
        final bool isXSmall = maxW < 600; // mobile

        double fw(double desired) {
          if (isXSmall) return maxW - 40;
          // On very narrow screens reduce to a range
          if (isSmall) return desired.clamp(110, 220);
          return desired; // large keep original
        }

        // Only allow filtering by status "PTHC" and "Leader" on this screen
        final statusOptions = <Map<String, String>>[
          {'code': 'PTHC', 'label': 'PTHC'},
          {'code': 'Leader', 'label': 'Leader'},
        ];

        Widget statusDropdown = SizedBox(
          width: fw(150),
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
                  value: option['code']!,
                  child: Text(
                    option['label']!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => controller.updateStatus(value),
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 20,
              ),
              menuMaxHeight: 200,
            ),
          ),
        );

        final List<Widget> filters = [
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
          // chọn phòng ban
          SizedBox(
            width: fw(200),
            child: Obx(
              () => DropdownButtonFormField<String>(
                value: controller.departmentQuery.value.isEmpty
                    ? null
                    : controller.departmentQuery.value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr('department'),
                  labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: Icon(
                    Iconsax.building_4,
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
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.blue[300]!,
                      width: 1.5,
                    ),
                  ),
                  isDense: true,
                ),
                hint: Text(
                  tr('department'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                items:
                    [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                          tr('all'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ] +
                    controller.listSection
                        .map(
                          (section) => DropdownMenuItem<String>(
                            value: section,
                            child: Text(
                              section,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  controller.updateDepartment(value ?? '');
                },
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Colors.grey[600],
                ),
                menuMaxHeight: 320,
                dropdownColor: Colors.white,
              ),
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
          // Status dropdown (PTHC / Leader)
          if (authState.user!.chRGroup.toString() == "PTHC") statusDropdown,
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
            onPressed: () => _ReturnSDialog(
              authState.user!.chRUserid.toString(),
              sectionName,
              authState.user!.chRGroup.toString(),
            ),
          ),
          // buildActionButton(
          //   icon: Icons.upload_file,
          //   color: Colors.indigo,
          //   tooltip: tr('importExcel'),
          //   onPressed: () => _pickAndImportExcel(authState),
          // ),

          //    // Download error Excel if exists
          //   Obx(() => controller.lastImportErrorExcel.value == null
          //       ? const SizedBox()
          //       : buildActionButton(
          //           icon: Icons.download,
          //           color: Colors.red,
          //           tooltip: tr('downloadErrors'),
          //           onPressed: () => _downloadImportErrors(),
          //         )),
        ];

        // Simple search/filter container only
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

  // Pick Excel file and import evaluation results via controller.importExceltoApp
  // Future<void> _pickAndImportExcel(AuthState authState) async {
  //   final dash = Get.find<DashboardControllerApprentice>();
  //   try {
  //     if (kIsWeb) {
  //       final result = await FilePicker.platform.pickFiles(
  //         type: FileType.custom,
  //         allowedExtensions: ['xlsx', 'xls', 'xlsm'],
  //         withData: true,
  //       );
  //       if (result == null || result.files.isEmpty) return;
  //       final file = result.files.first;
  //       final bytes = file.bytes;
  //       if (bytes == null) {
  //         Get.snackbar('Import', 'Không đọc được dữ liệu file');
  //         return;
  //       }
  //       await dash.importExceltoApp(
  //         bytes,
  //         authState.user!.chRUserid.toString(),
  //       );
  //     } else {
  //       final result = await FilePicker.platform.pickFiles(
  //         type: FileType.custom,
  //         allowedExtensions: ['xlsx', 'xls', 'xlsm'],
  //       );
  //       if (result == null || result.files.isEmpty) return;
  //       final path = result.files.first.path;
  //       if (path == null) return;
  //       final file = File(path);
  //       final bytes = await file.readAsBytes();
  //       await dash.importExceltoApp(
  //         bytes,
  //         authState.user!.chRUserid.toString(),
  //       );
  //     }
  //     // Tự động tải file lỗi nếu có (Web only)
  //     if (dash.lastImportErrorExcel.value != null && kIsWeb) {
  //       final errorBytes = dash.lastImportErrorExcel.value!;
  //       final blob = html.Blob([
  //         errorBytes,
  //       ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  //       final url = html.Url.createObjectUrlFromBlob(blob);
  //       html.AnchorElement(href: url)
  //         ..setAttribute('download', 'import_errors_apprentice.xlsx')
  //         ..click();
  //       html.Url.revokeObjectUrl(url);
  //     }
  //     if (dash.lastImportErrors.isNotEmpty) {
  //       Get.snackbar(
  //         'Import',
  //         'Hoàn tất với lỗi. Đã xuất file lỗi (nếu Web). Tổng lỗi: ${dash.lastImportErrors.length}',
  //         snackPosition: SnackPosition.BOTTOM,
  //       );
  //     } else {
  //       Get.snackbar('Import', 'Import dữ liệu thành công');
  //     }
  //   } catch (e) {
  //     Get.snackbar('Import lỗi', e.toString());
  //   }
  // }

  // Download error Excel (web only currently)
  // void _downloadImportErrors() {
  //   final dash = Get.find<DashboardControllerApprentice>();
  //   final bytes = dash.lastImportErrorExcel.value;
  //   if (bytes == null) return;
  //   if (kIsWeb) {
  //     final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  //     final url = html.Url.createObjectUrlFromBlob(blob);
  //     html.AnchorElement(href: url)
  //       ..setAttribute('download', 'import_errors_two.xlsx')
  //       ..click();
  //     html.Url.revokeObjectUrl(url);
  //   } else {
  //     Get.snackbar('Download', 'Chức năng tải lỗi đang hỗ trợ trên Web');
  //   }
  // }
  // Combined layout for header, search, and evaluation note side-by-side (wide screens)
  Widget _buildHeaderSearchWithNote() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide =
            constraints.maxWidth > 1000; // breakpoint for row layout
        if (!isWide) {
          // Fallback stacked layout for narrow screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildSearchAndActions(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildSearchAndActions(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: _buildEvaluationNoteStandalone()),
          ],
        );
      },
    );
  }

  Widget _buildEvaluationNoteStandalone() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 6),
              Text(
                'Ghi chú / 備考',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildNoteLine(
            'Cột kết quả lựa chọn trong các kết quả sau / 下記の評価結果を選抜してから記入下さい:',
          ),
          _buildStatusLine(
            'NG',
            'Không đạt. Công ty không ký tiếp hợp đồng /不合格。会社は契約を更新されない。',
            Colors.red,
          ),
          _buildNoteLine(
            '※ Kết quả chung là NG khi có ít nhất một hạng mục bị đánh giá là NG /評価案内：一般評価には一項がNGであれば、評価がNGとなる',
            leading: '※',
          ),
          _buildStatusLine(
            'OK',
            'Đạt. Công ty sẽ tiếp tục ký Hợp đồng 2 năm /合格。引き続き2年間の契約を更新します',
            Colors.green,
          ),
          _buildStatusLine(
            'Finish L/C',
            'CNV không muốn ký tiếp hợp đồng/ 従業者が契約を続けたくない',
            Colors.blue,
          ),
          _buildStatusLine(
            'Stop Working',
            'CNV đã viết đơn nghỉ việc/ 従業者が退職書を書きました',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteLine(String text, {String? leading}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 2),
              child: Text(
                leading,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine(String code, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6, bottom: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.6), width: 0.8),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.darken(),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            TextSpan(text: desc),
          ],
        ),
      ),
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

  Widget _buildFrozenDataTable() {
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
            Expanded(child: _buildFrozenBody()),
            _buildCustomPaginator(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrozenBody() {
    final dataSource = MyData(context);
    final total = controller.filterdataList.length;
    if (_firstRowIndex >= total && total > 0) {
      _firstRowIndex = (total - 1) - ((total - 1) % _rowsPerPage);
    }
    final endIndex = (_firstRowIndex + _rowsPerPage) > total
        ? total
        : (_firstRowIndex + _rowsPerPage);
    final visibleCount = endIndex - _firstRowIndex;
    final fullRows = List.generate(
      visibleCount,
      (i) => dataSource.getRow(_firstRowIndex + i) as DataRow2,
    );
    final frozenCols = <DataColumn>[
      DataColumnCustom(
        title: tr('stt'),
        width: 70,
        onSort: controller.sortById,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
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
    ];
    final scrollCols = <DataColumn>[
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
        width: 150,
        maxLines: 3,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('baocao'),
        width: 130,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('chaphanh'),
        width: 130,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('ketqua'),
        width: 150,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('note'),
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('notRehirable'),
        width: 170,
        maxLines: 2,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('Lydo'),
        width: 170,
        maxLines: 2,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('Apporval'),
        width: 100,
        maxLines: 2,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
      DataColumnCustom(
        title: tr('LydoTuChoi'),
        width: 170,
        maxLines: 2,
        fontSize: Common.sizeColumn,
      ).toDataColumn2(),
    ];
    final frozenCount = frozenCols.length;
    final frozenRows = <DataRow>[];
    final scrollRows = <DataRow>[];
    for (final r in fullRows) {
      final cells = r.cells;
      frozenRows.add(
        DataRow(
          selected: r.selected,
          onSelectChanged: r.onSelectChanged,
          color: r.color,
          cells: cells.take(frozenCount).toList(),
        ),
      );
      scrollRows.add(
        DataRow(
          selected: r.selected,
          onSelectChanged: r.onSelectChanged,
          color: r.color,
          cells: cells.skip(frozenCount).toList(),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 900),
          child: Scrollbar(
            controller: _leftVerticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _leftVerticalController,
              child: DataTable(
                headingRowHeight: 66,
                dataRowHeight: 56,
                showCheckboxColumn: true,
                columns: frozenCols,
                rows: frozenRows,
              ),
            ),
          ),
        ),
        Container(width: 1, color: Colors.grey[300]),
        Expanded(
          child: Scrollbar(
            controller: _rightScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _rightScrollController,
              scrollDirection: Axis.horizontal,
              child: Scrollbar(
                controller: _rightVerticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _rightVerticalController,
                  child: DataTable(
                    headingRowHeight: 66,
                    dataRowHeight: 56,
                    showCheckboxColumn: false,
                    columns: scrollCols,
                    rows: scrollRows,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
                  setCellValue(
                    'O',
                    item.inTStatusId == 3 ? "" : (item.vchRLyThuyet ?? ''),
                  );
                  setCellValue(
                    'P',
                    item.inTStatusId == 3 ? "" : (item.vchRThucHanh ?? ''),
                  );
                  setCellValue(
                    'Q',
                    item.inTStatusId == 3 ? "" : (item.vchRCompleteWork ?? ''),
                  );
                  setCellValue(
                    'R',
                    item.inTStatusId == 3 ? "" : (item.vchRLearnWork ?? ''),
                  );
                  setCellValue(
                    'S',
                    item.inTStatusId == 3 ? "" : (item.vchRThichNghi ?? ''),
                  );
                  setCellValue(
                    'T',
                    item.inTStatusId == 3 ? "" : (item.vchRUseful ?? ''),
                  );
                  setCellValue(
                    'U',
                    item.inTStatusId == 3 ? "" : (item.vchRContact ?? ''),
                  );
                  setCellValue(
                    'V',
                    item.inTStatusId == 3 ? "" : (item.vcHNeedViolation ?? ''),
                  );
                  setCellValue(
                    'W',
                    item.inTStatusId == 3
                        ? ""
                        : (item.vchRReasultsLeader ?? ''),
                  );
                  setCellValue(
                    'X',
                    item.inTStatusId == 3 ? "" : (item.vchRNote ?? ''),
                  );
                  setCellValue(
                    'Y',
                    item.biTNoReEmployment == null
                        ? ""
                        : (item.biTNoReEmployment ? "" : "X"),
                  );
                  setCellValue(
                    'Z',
                    item.inTStatusId == 3
                        ? ""
                        : (item.nvchRNoReEmpoyment ?? ''),
                  );
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

  void _ReturnSDialog(String adid, String sectionName, String group) {
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
                await controller.updateListContractReturnSPTHC(
                  adid,
                  reasonController.text,
                );
                if (group == "PTHC" || group == "Admin") {
                  // truong hop PTHC phong ban

                  await controller.changeStatus(
                    'PTHC',
                    sectionName,
                    adid,
                    null,
                  );
                } else if (group == "Chief") {
                  await controller.changeStatus(
                    '5',
                    sectionName,
                    adid.toString(),
                    null,
                  );
                } else {
                  // truong hop leader
                  await controller.changeStatus('4', sectionName, adid, null);
                }
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

  Widget _buildCopyCell(String? value, {bool highlight = false}) {
    final txt = value ?? '';
    return InkWell(
      onTap: () => _copyToClipboard(txt),
      child: Row(
        children: [
          Icon(
            Icons.copy,
            size: 14,
            color: highlight ? Colors.red[700] : Colors.grey[600],
          ),
          Expanded(
            child: Text(
              txt,
              style: TextStyle(
                fontSize: Common.sizeColumn,
                color: highlight ? Colors.red[900] : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
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
      text: data.nvchRNoReEmpoyment ?? '',
    );
    final returnController = TextEditingController(
      text: [
        data.nvchRNoReEmpoyment,
        data.nvchRApproverChief,
        data.nvchRApproverManager,
        data.nvchRApproverDirector,
      ].firstWhere((e) => e != null && e != '', orElse: () => ''),
    );
    final noteController = TextEditingController(text: data.vchRNote ?? '');
    final bool isReturn = (!data.biTNoReEmployment && data.inTStatusId == 3);
    TextStyle cellCenterStyle() => TextStyle(
      fontSize: Common.sizeColumn,
      color: isReturn ? Colors.red[900] : null,
    );
    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>((states) {
        if (isReturn) {
          return Colors.red.withOpacity(
            states.contains(MaterialState.selected) ? 0.35 : 0.18,
          );
        }
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
              color: isReturn ? Colors.red[900] : Colors.blue[800],
              fontSize: Common.sizeColumn, // Added fontSize 12
            ),
          ),
        ),
        //Action
        DataCell(
          Center(
            child: _buildActionButton(
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
          ),
        ),
        DataCell(_getHienTrangColor(data.inTStatusId)),
        // Copyable vchRCodeApprover
        DataCell(
          _buildCopyCell(data.vchRCodeApprover ?? "", highlight: isReturn),
        ),
        // Copyable vchREmployeeId
        DataCell(_buildCopyCell(data.vchREmployeeId, highlight: isReturn)),
        DataCell(Text(data.vchRTyperId ?? "", style: cellCenterStyle())),
        // Copyable vchREmployeeName
        DataCell(_buildCopyCell(data.vchREmployeeName, highlight: isReturn)),
        DataCell(
          _buildCopyCell(data.vchRNameSection ?? "", highlight: isReturn),
        ),
        DataCell(
          _buildCopyCell(data.chRCostCenterName ?? "", highlight: isReturn),
        ),
        DataCell(
          Text(
            data.dtMBrithday != null
                ? '${DateTime.now().difference(DateTime.parse(data.dtMBrithday!)).inDays ~/ 365}'
                : "",
            style: cellCenterStyle(),
          ),
        ),
        DataCell(Text(data.chRPosition ?? "", style: cellCenterStyle())),
        DataCell(
          Text(data.chRCodeGrade?.toString() ?? "", style: cellCenterStyle()),
        ),
        DataCell(
          Text(
            data.dtMJoinDate != null
                ? DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(data.dtMJoinDate!))
                : "",
            style: cellCenterStyle(),
          ),
        ),
        DataCell(
          Text(
            data.dtMEndDate != null
                ? DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(data.dtMEndDate!))
                : "",
            style: cellCenterStyle(),
          ),
        ),
        DataCell(
          Text(data.fLGoLeaveLate?.toString() ?? "", style: cellCenterStyle()),
        ),
        DataCell(
          Text(data.fLNotLeaveDay?.toString() ?? "", style: cellCenterStyle()),
        ),
        DataCell(
          Text(data.inTViolation?.toString() ?? "", style: cellCenterStyle()),
        ),
        DataCell(
          Text(
            data.nvarchaRViolation?.toString() ?? "",
            style: cellCenterStyle(),
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRLyThuyet ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRThucHanh ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRCompleteWork ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRLearnWork ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRThichNghi ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRUseful ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRContact ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vcHNeedViolation ?? 'OK',
              );
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
            if (intStatus == 5) {
              return _getDanhGiaView(
                controller.filterdataList[index].vchRReasultsLeader ?? 'OK',
              );
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

        // Ghi chú
        DataCell(
          (data.inTStatusId ?? 0) == 3
              ? Text('', style: TextStyle(fontSize: Common.sizeColumn))
              : Focus(
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
        // Truong hop tuyen dung lai hay khong
        DataCell(
          Builder(
            builder: (_) {
              final intStatus = data.inTStatusId ?? 0;
              if (intStatus == 3) {
                return Text('', style: TextStyle(fontSize: Common.sizeColumn));
              }
              // Chỉ wrap phần thật sự phụ thuộc vào observable bằng Obx
              return Obx(() {
                final list = controller.filterdataList; // observable read
                if (index >= list.length) {
                  return const SizedBox.shrink();
                }
                final raw = list[index].biTNoReEmployment ?? true;
                if (intStatus == 5) {
                  return Row(
                    children: [
                      Icon(
                        raw ? Icons.check_circle : Icons.cancel,
                        color: raw ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        raw ? 'O' : 'X',
                        style: TextStyle(
                          fontSize: Common.sizeColumn,
                          color: raw ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  );
                }
                return DropdownButton<String>(
                  value: raw ? 'OK' : 'NG',
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
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
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
                          const Icon(Icons.cancel, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
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
              });
            },
          ),
        ),
        // Lý do không tuyển lại
        DataCell(
          (() {
            final intStatus = data.inTStatusId ?? 0;
            if (intStatus == 3) {
              return Text('', style: TextStyle(fontSize: Common.sizeColumn));
            }
            if (intStatus == 5) {
              // Read-only hiển thị lý do không tuyển lại
              return Text(
                reasonController.text,
                style: TextStyle(fontSize: Common.sizeColumn),
              );
            }
            return Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
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
            );
          })(),
        ),

        /// phần từ chối phê duyệt
        // thuộc tính approver
        if (data.inTStatusId == 5)
          DataCell(
            Obx(() {
              Visibility(
                visible: false,
                child: Text(controller.filterdataList[index].toString()),
              );
              final rawStatus = () {
                if (controller.filterdataList.length > index) {
                  return switch (data.inTStatusId) {
                    5 =>
                      controller.filterdataList[index].biTApproverChief ?? true,
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
          )
        else
          DataCell(
            Obx(() {
              Visibility(
                visible: false,
                child: Text(controller.filterdataList[index].toString()),
              );
              final rawStatus = [
                data.nvchRNoReEmpoyment,
                data.nvchRApproverChief,
                data.nvchRApproverManager,
                data.nvchrApproverDeft,
                data.nvchRApproverDirector,
              ].firstWhere((e) => e != null && e != '', orElse: () => '');
              if (rawStatus == '') {
                return Text('', style: TextStyle(fontSize: Common.sizeColumn));
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
        // ly do tu choi phe duyet
        if (data.inTStatusId == 5)
          DataCell(
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  // Chỉ update khi mất focus
                  controller.updateNotRehireReasonApprovel(
                    data.vchREmployeeId.toString(),
                    returnController.text,
                    data.inTStatusId,
                  );
                }
              },
              child: TextFormField(
                controller: returnController,
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
          )
        else
          DataCell(
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  // // Chỉ update khi mất focus
                  // controller.updateNoteApprovel(
                  //   data.vchREmployeeId.toString(),
                  //   reasonController.text,
                  // );
                }
              },
              child: TextFormField(
                controller: returnController,
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

// A collapsible wrapper for small screens (top-level)
class _CollapsibleNote extends StatefulWidget {
  final Widget child;
  const _CollapsibleNote({required this.child});
  @override
  State<_CollapsibleNote> createState() => _CollapsibleNoteState();
}

class _CollapsibleNoteState extends State<_CollapsibleNote> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              foregroundColor: Colors.blue[800],
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_expanded ? 'Ẩn ghi chú / 隠す' : 'Ghi chú / 備考'),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.child,
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

// Extension method to slightly darken a Color
extension _ColorShade on Color {
  Color darken([double amount = .15]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
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
    RxString reson = ''.obs;
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
                  fontSize: 16,
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
                initialValue: reson.value,
                label: tr('reasonRejectHint'),
                onChanged: (value) => reson.value = value,
                maxLines: 2,
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
                      if (reson.value.isEmpty) {
                        errorMessage.value = tr('reasonRejectHint');
                        return;
                      }
                      await controller.sendEmailReturn(
                        edited,
                        authState.user!.chRUserid.toString(),
                        reson.value,
                      );
                      await controller.updateApprenticeContract(
                        edited,
                        authState.user!.chRUserid.toString(),
                      );
                      final parts =
                          authState.user!.chRSecCode?.toString().split(':') ??
                          [];
                      String sectionName = parts.length >= 2
                          ? '${parts[0].trim()} : ${parts[1].trim()}'
                          : parts.firstOrNull?.trim() ?? '';
                      // phan xem ai dang vao man so sanh
                      if (authState.user!.chRGroup.toString() == "PTHC" ||
                          authState.user!.chRGroup.toString() == "Per" ||
                          authState.user!.chRGroup.toString() == "Admin") {
                        // truong hop PTHC phong ban
                        await controller.changeStatus(
                          'PTHC',
                          sectionName,
                          authState.user!.chRUserid.toString(),
                          null,
                        );
                      } else if (authState.user!.chRGroup.toString() ==
                          "Chief") {
                        await controller.changeStatus(
                          '5',
                          sectionName,
                          authState.user!.chRUserid.toString(),
                          null,
                        );
                      } else {
                        // truong hop leader
                        await controller.changeStatus(
                          '4',
                          sectionName,
                          authState.user!.chRUserid.toString(),
                          null,
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
