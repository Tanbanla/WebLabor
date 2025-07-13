import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class MasterPTHC extends StatefulWidget {
  const MasterPTHC({super.key});

  @override
  State<MasterPTHC> createState() => _MasterPTHCState();
}

class _MasterPTHCState extends State<MasterPTHC> {
  @override
  Widget build(BuildContext context) {
    final DashboardControllerPTHC controller = Get.put(DashboardControllerPTHC());
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Master quản lý thông tin PTHC',
                    style: TextStyle(
                      color: Common.primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              Row(
                children: [
                  // Ô tìm kiếm
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: controller.searchTextController,
                        onChanged: (value) => controller.searchQuery(value),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm...',
                          prefixIcon: Icon(Iconsax.search_normal, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Button Export
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: IconButton(
                      icon: Icon(Iconsax.export, color: Colors.green, size: 20),
                      tooltip: 'Xuất dữ liệu',
                      onPressed: () {
                        // Xử lý xuất dữ liệu
                        
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Button Import
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: IconButton(
                      icon: Icon(Iconsax.import, color: Colors.blue, size: 20),
                      tooltip: 'Nhập dữ liệu',
                      onPressed: () {
                        // Xử lý nhập dữ liệu
                        
                      },
                    ),
                  ),
                ],
              ),
              Obx(() {
                Visibility(
                  visible: false,
                  child: Text(controller.filterdataList.length.toString()),
                );
                return SizedBox(
                  height: 760,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardTheme: const CardThemeData(
                        color: Colors.white,
                        elevation: 0,
                      ),
                    ),
                    child: PaginatedDataTable2(
                      columnSpacing: 12,
                      minWidth: 100,
                      dividerThickness: 0,
                      horizontalMargin: 12,
                      dataRowHeight: 56,
                      headingTextStyle: Theme.of(context).textTheme.titleMedium,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.transparent, // mau heading
                      ),
                      headingRowDecoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      // checkbox column
                      showCheckboxColumn: true,

                      // PAGINATION
                      showFirstLastButtons: true,
                      onPageChanged: (value) {},
                      renderEmptyRowsInTheEnd: false,
                      availableRowsPerPage: const [5, 10, 15, 20, 25, 50, 100],
                      onRowsPerPageChanged:(value) {
                      },
                      //rowsPerPage: 11, // number rows seen

                      // Sorting
                      sortAscending: controller.sortAscending.value,
                      sortArrowAlwaysVisible: false,
                      sortArrowIcon: Icons.line_axis,
                      sortColumnIndex: controller.sortCloumnIndex.value,
                      sortArrowBuilder: (ascending, sorted) {
                        if (sorted) {
                          return Icon(
                            ascending ? Iconsax.arrow_up3 : Iconsax.arrow_down,
                            size: 16,
                          );
                        } else {
                          return const Icon(Iconsax.arrow_3, size: 16);
                        }
                      },

                      columns: [
                        DataColumn2(
                          label: Text(
                            "Phòng ban",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          fixedWidth: 130,
                          onSort: (columnIndex, ascending) =>
                              controller.sortById(columnIndex, ascending),
                        ),
                        DataColumn2(
                          label: Text(
                            "Mail to",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn2(
                          label: Text(
                            "Mail CC",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn2(
                          label: Text(
                            "Hành động",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          fixedWidth: 200,
                        ),
                      ],
                      source: MyData(),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class MyData extends DataTableSource {
  final DashboardControllerPTHC controller = Get.find();
  @override
  DataRow? getRow(int index) {
    final data = controller.filterdataList[index];
    return DataRow2(
      onTap: () {},
      selected: controller.selectRows[index],
      onSelectChanged: (value) {
        controller.selectRows[index] = value ?? false;
        controller.selectRows.refresh();
        notifyListeners();
      },
      cells: [
        DataCell(Text(data['Column1'] ?? "")),
        DataCell(Text(data['Column2'] ?? "")),
        DataCell(Text(data['Column3'] ?? "")),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút Sửa
              ElevatedButton.icon(
                icon: Icon(Icons.edit, size: 16),
                label: Text("Sửa"),
                onPressed: () => _handleEdit(data),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue[50],
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Nút Xóa
              ElevatedButton.icon(
                icon: Icon(Icons.delete, size: 16),
                label: Text("Xóa"),
                onPressed: () => _handleDelete(data),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red[50],
                  backgroundColor: Colors.red,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
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
  void _handleEdit(Map<String, String> data) {
    // Hiển thị dialog hoặc mở màn hình chỉnh sửa
    Get.dialog(
      AlertDialog(
        title: Text("Sửa dữ liệu"),
        content: Text("Bạn muốn sửa ${data['Column1']}?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              // Logic sửa dữ liệu
              Get.back();
            },
            child: Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  void _handleDelete(Map<String, String> data) {
    // Hiển thị dialog xác nhận xóa
    Get.dialog(
      AlertDialog(
        title: Text("Xóa dữ liệu"),
        content: Text("Bạn chắc chắn muốn xóa ${data['Column1']}?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              // Logic xóa dữ liệu
              controller.deleteItem(data);
              Get.back();
            },
            child: Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class DashboardControllerPTHC extends GetxController {
  var dataList = <Map<String, String>>[].obs;
  var filterdataList = <Map<String, String>>[].obs;
  RxList<bool> selectRows = <bool>[].obs;

  RxInt sortCloumnIndex = 1.obs;
  RxBool sortAscending = true.obs;
  final searchTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchDumyData();
  }

  void sortById(int sortColumnIndex, bool ascending) {
    sortAscending.value = ascending;
    filterdataList.sort((a, d) {
      if (ascending) {
        return filterdataList[0]['Column1'].toString().toLowerCase().compareTo(
          filterdataList[0]['Column1'].toString().toLowerCase(),
        );
      } else {
        return filterdataList[0]['Column1'].toString().toLowerCase().compareTo(
          filterdataList[0]['Column1'].toString().toLowerCase(),
        );
      }
    });
    this.sortCloumnIndex.value = sortColumnIndex;
  }

  void searchQuery(String query) {
    filterdataList.assignAll(
      dataList.where((item) => item['Column2']!.contains(query.toLowerCase())),
    );
  }

  void deleteItem(Map<String, String> item) {
    dataList.remove(item);
    filterdataList.remove(item);
    selectRows.removeAt(dataList.indexOf(item));
  }

  void fetchDumyData() {
    selectRows.assignAll(List.generate(36, (index) => false));
    dataList.addAll(
      List.generate(
        36,
        (index) => {
          'Column1': 'RD ${index + 1}-1',
          'Column2': 'exempler@${index + 1}-2@gmail.com',
          'Column3': 'exempler@${index + 1}-3@gmail.com',
        },
      ),
    );
    filterdataList.addAll(
      List.generate(
        36,
        (index) => {
          'Column1': 'RD ${index + 1}-1',
          'Column2': 'exempler@${index + 1}-2@gmail.com',
          'Column3': 'exempler@${index + 1}-3@gmail.com',
        },
      ),
    );
  }
}
