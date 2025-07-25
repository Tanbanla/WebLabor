import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Screen/Admin/Master/temp_pthc.dart';
import 'package:web_labor_contract/Screen/User/Approver/approval_prepartion.dart';
import 'package:web_labor_contract/Screen/User/Approver/approval_trial.dart';
import 'package:web_labor_contract/Screen/User/Approver/approval_two.dart';
import 'package:web_labor_contract/Screen/User/CreateContract/apprentice_contract.dart';
import 'package:web_labor_contract/Screen/User/CreateContract/two_contract.dart';
import 'package:web_labor_contract/Screen/Admin/Master/master_pthc.dart';
import 'package:web_labor_contract/Screen/Admin/Master/master_user.dart';
import 'package:web_labor_contract/Screen/User/Fill_Review/fill_apprentice.dart';
import 'package:web_labor_contract/Screen/User/Fill_Review/fill_two.dart';
import 'package:web_labor_contract/Screen/User/Home/home_screen.dart';
import 'package:web_labor_contract/class/CMD.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Widget _currentBody = HomeScreen(changeBody: (newBody) {},); //TwoContractScreen();

  // // Hàm này sẽ được truyền xuống drawer
  // void _changeBody(Widget newBody) {
  //   setState(() {
  //     _currentBody = newBody;
  //     Navigator.of(context).pop();
  //   });
  // }
  late Widget _currentBody; // Sử dụng late thay vì khởi tạo ngay

  @override
  void initState() {
    super.initState();
    _currentBody = //TwoContractScreen();
    HomeScreen(
      changeBody: _changeBody,
    ); // Khởi tạo trong initState
  }

  void _changeBody(Widget newBody) {
    if (!mounted) return; // Kiểm tra mounted trước khi setState

    setState(() {
      _currentBody = newBody;
      Navigator.of(context).pop(); // Đóng drawer nếu đang mở
    });
  }

  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      //body: body(),
      body: _currentBody,
      // is HomeScreen
      //     ? HomeScreen(changeBody: _changeBody) // Truyền callback khi là HomeScreen
      //     : body(),
      drawer: ComplexDrawer(
        changeBody: _changeBody, // Truyền hàm callback xuống drawer
      ),
      drawerScrimColor: Colors.transparent,
      backgroundColor: Colors.white,
    );
  }

  AppBar appBar() {
    return AppBar(
      iconTheme: IconTheme.of(context).copyWith(color: Colors.white),
      title: Text(
        "LABOR CONTRACT EVALUATION",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Common.primaryColor,//.withOpacity(0.6),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button tiếng Anh
              IconButton(
                icon: Image.asset(
                  'assets/img/jp.png',
                  height: 24, // Giảm kích thước cho phù hợp AppBar
                  width: 40,
                  fit: BoxFit.cover,
                ),
                onPressed: () {
                  setState(() {
                    // Gọi hàm thay đổi ngôn ngữ ở đây
                  });
                },
              ),
              // Button tiếng Việt
              IconButton(
                icon: Image.asset(
                  'assets/img/vn.jpg',
                  height: 24, // Giảm kích thước cho phù hợp AppBar
                  width: 40,
                  fit: BoxFit.cover,
                ),
                onPressed: () {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget body() {
    return Center(
      child: Container(
        foregroundDecoration: BoxDecoration(
          color: Common.primaryColor,
          backgroundBlendMode: BlendMode.saturation,
        ),
        child: _currentBody,
      ),
    );
  }
}

class ComplexDrawer extends StatefulWidget {
  final Function(Widget) changeBody; // Callback để thay đổi giao diện

  const ComplexDrawer({Key? key, required this.changeBody}) : super(key: key);

  @override
  _ComplexDrawerState createState() => _ComplexDrawerState();
}

class _ComplexDrawerState extends State<ComplexDrawer> {
  int selectedIndex = -1; //dont set it to 0

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      // do dai menu
      //width: width/2,
      child: row(),
      // color:
      // Color.fromARGB(255, 119, 201, 146).withOpacity(0.2),
    );
  }

  Widget row() {
    return Row(
      children: [
        isExpanded ? blackIconTiles() : blackIconMenu(),
        invisibleSubMenus(),
      ],
    );
  }

  Widget blackIconTiles() {
    return Container(
      width: 300,
      color: Color.fromARGB(255, 69, 136, 78),
      child: Column(
        children: [
          controlTile(),
          Expanded(
            child: ListView.builder(
              itemCount: cdms.length,
              itemBuilder: (BuildContext context, int index) {
                //  if(index==0) return controlTile();
                CDM cdm = cdms[index];
                bool selected = selectedIndex == index;
                return ExpansionTile(
                  onExpansionChanged: (z) {
                    setState(() {
                      selectedIndex = z ? index : -1;
                    });
                  },
                  leading: Icon(cdm.icon, color: Colors.white),
                  title: Text(cdm.title, style: TextStyle(color: Colors.white)),
                  trailing: cdm.submenus.isEmpty
                      ? null
                      : Icon(
                          selected
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                  children: cdm.submenus.map((subMenu) {
                    return sMenuButton(subMenu, false, cdm.title);
                  }).toList(),
                );
              },
            ),
          ),
          accountTile(),
        ],
      ),
    );
  }

  Widget controlTile() {
    return Container(
      decoration: BoxDecoration(
        color: Common.primaryColor,
        borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 20, bottom: 30),
        child: ListTile(
          leading: FlutterLogo(),
          title: Text(
            "LABOR CONTRACT EVALUATION",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: expandOrShrinkDrawer,
        ),
      ),
    );
  }

  Widget blackIconMenu() {
    return AnimatedContainer(
      duration: Duration(seconds: 1),
      width: 100,
      color: Common.primaryColor,
      child: Column(
        children: [
          controlButton(),
          Expanded(
            child: ListView.builder(
              itemCount: cdms.length,
              itemBuilder: (contex, index) {
                // if(index==0) return controlButton();
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    height: 45,
                    alignment: Alignment.center,
                    child: Icon(cdms[index].icon, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          accountButton(),
        ],
      ),
    );
  }

  Widget invisibleSubMenus() {
    // List<CDM> _cmds = cdms..removeAt(0);
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      width: isExpanded ? 0 : 200,
      color: Color.fromARGB(255, 119, 201, 146).withOpacity(0.4),
      child: Column(
        children: [
          Container(height: 95),
          Expanded(
            child: ListView.builder(
              itemCount: cdms.length,
              itemBuilder: (context, index) {
                CDM cmd = cdms[index];
                // if(index==0) return Container(height:95);
                //controll button has 45 h + 20 top + 30 bottom = 95

                bool selected = selectedIndex == index;
                bool isValidSubMenu = selected && cmd.submenus.isNotEmpty;
                return subMenuWidget(
                  [cmd.title]..addAll(cmd.submenus),
                  isValidSubMenu,
                  cmd.title,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget controlButton() {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 30),
      child: InkWell(
        onTap: expandOrShrinkDrawer,
        child: Container(
          height: 45,
          alignment: Alignment.center,
          child: FlutterLogo(size: 40),
        ),
      ),
    );
  }

  Widget subMenuWidget(
    List<String> submenus,
    bool isValidSubMenu,
    String title,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      height: isValidSubMenu ? submenus.length.toDouble() * 70 : 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isValidSubMenu
            ? Common.primaryColor.withOpacity(0.7)
            : Colors.transparent,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(6),
        itemCount: isValidSubMenu ? submenus.length : 0,
        itemBuilder: (context, index) {
          String subMenu = submenus[index];

          return sMenuButton(subMenu, index == 0, title);
        },
      ),
    );
  }

  Widget sMenuButton(String subMenu, bool isTitle, String title) {
    return InkWell(
      onTap: () {
        if (!isTitle) {
          // Xử lý chuyển đổi giao diện dựa trên subMenu được chọn
          switch (subMenu) {
            case "Quản lý User":
              widget.changeBody(MasterUser());
              break;
            case "Thông tin PTHC":
              widget.changeBody(MasterPTHC());
              break;
            case "Hợp đồng không xác định thời gian":
              if (title == "Lập đánh giá") {
                widget.changeBody(TwoContractScreen());
              }
              if (title == "Điền đánh giá") {
                widget.changeBody(FillTwoScreen());
              }
              if (title == "Phê duyệt") {
                widget.changeBody(ApprovalTwoScreen());
              }
              break;
            case "Hợp đồng thử nghề & học việc":
              if (title == "Lập đánh giá") {
                widget.changeBody(ApprenticeContract());
              }
              if (title == "Điền đánh giá") {
                widget.changeBody(FillApprenticeScreen());
              }
              if (title == "Phê duyệt") {
                widget.changeBody(ApprovalTrialScreen());
              }
              break;
            case "Phê duyệt chuẩn bị":
              widget.changeBody(ApprovalPrepartionScreen());
              break;
            case "Trang chủ":
              widget.changeBody(HomeScreen(changeBody: (newPage) {}));
              return;
            default:
              widget.changeBody(HomeScreen(changeBody: (newPage) {}));
          }
        }
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8.0),
        child: Text(
          subMenu,
          style: TextStyle(
            fontSize: isTitle ? 17 : 14,
            color: isTitle ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget accountButton({bool usePadding = true}) {
    return Padding(
      padding: EdgeInsets.all(usePadding ? 8 : 0),
      child: AnimatedContainer(
        duration: Duration(seconds: 1),
        height: 45,
        width: 45,
        decoration: BoxDecoration(
          color: Colors.white70,
          image: DecorationImage(
            //ảnh
            image: AssetImage('assets/img/profile.jpg'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget accountTile() {
    return Container(
      color: Common.primaryColor,
      child: ListTile(
        leading: accountButton(usePadding: false),
        title: Text("Welcome", style: TextStyle(color: Colors.white)),
        subtitle: Text(
          "Nguyễn Duy Khánh",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  static List<CDM> cdms = [
    CDM(Icons.home, "Home", ["Trang chủ"]),
    CDM(Icons.grid_view, "Master", [
      "Quản lý User",
      "Thông tin PTHC",
      "Danh sách màn hình",
    ]),
    CDM(Icons.subscriptions, "Lập đánh giá", [
      "Hợp đồng thử nghề & học việc",
      "Hợp đồng không xác định thời gian",
      "Phê duyệt chuẩn bị",
    ]),
    CDM(Icons.explore, "Điền đánh giá", [
      "Hợp đồng thử nghề & học việc",
      "Hợp đồng không xác định thời gian",
    ]),
    CDM(Icons.markunread_mailbox, "Phê duyệt", [
      "Hợp đồng thử nghề & học việc",
      "Hợp đồng không xác định thời gian",
    ]),
    CDM(Icons.pie_chart, "Báo cáo", [
      "Hợp đồng thử nghề & học việc",
      "Hợp đồng không xác định thời gian",
    ]),
    // CDM(Icons.power, "Plugins", []),
    CDM(Icons.settings, "Setting", []),
  ];

  void expandOrShrinkDrawer() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }
}
