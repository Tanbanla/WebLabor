import 'package:flutter/material.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
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
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

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
        changeBody: _changeBody,
        context: context, // Truyền hàm callback xuống drawer
      ),
      drawerScrimColor: Colors.transparent,
      backgroundColor: Colors.white,
    );
  }

  AppBar appBar() {
    return AppBar(
      iconTheme: IconTheme.of(context).copyWith(color: Colors.white),
      title: Text(
        'appTitle'.tr(),
        //"LABOR CONTRACT EVALUATION",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Common.primaryColor, //.withOpacity(0.6),
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
                  context.setLocale(Locale('ja'));
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
                  context.setLocale(Locale('vi'));
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
  final BuildContext context;

  const ComplexDrawer({Key? key, required this.changeBody, required this.context}) : super(key: key);

  @override
  _ComplexDrawerState createState() => _ComplexDrawerState();
}

class _ComplexDrawerState extends State<ComplexDrawer> {
  int selectedIndex = -1; //dont set it to 0
  bool isExpanded = false;
  List<CDM> get cdms {
    return [
      CDM(Icons.home, 'home'.tr(), ['home'.tr()]),
      CDM(Icons.grid_view, "master".tr(), [
        "userManagement".tr(),
        "pthcInfo".tr(),
        "screenList".tr(),
      ]),
      CDM(Icons.subscriptions, 'createEvaluation'.tr(), [
        "trialContract".tr(),
        "indefiniteContract".tr(),
        "preparationApproval".tr(),
      ]),
      CDM(Icons.explore, "fillEvaluation".tr(), [
        "trialContract".tr(),
        "indefiniteContract".tr(),
      ]),
      CDM(Icons.markunread_mailbox, "approval".tr(), [
        "trialContract".tr(),
        "indefiniteContract".tr(),
      ]),
      CDM(Icons.pie_chart, "report".tr(), [
        "trialContract".tr(),
        "indefiniteContract".tr(),
      ]),
      CDM(Icons.settings, "settings".tr(), []),
    ];
  }

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
            'appTitle'.tr(),
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
          final currentLang = context.locale.languageCode;
          final userManagementText = currentLang == 'vi'
              ? 'Quản lý User'
              : 'ユーザー管理';
          final pthcInfoText = currentLang == 'vi'
              ? 'Thông tin PTHC'
              : 'PTHC情報';
          final indefiniteContractText = currentLang == 'vi'
              ? 'Hợp đồng không xác định thời gian'
              : '期間不定の契約';
          final trialContractText = currentLang == 'vi'
              ? 'Hợp đồng học nghề & thử việc'
              : '試用・研修契約';
          final preparationApprovalText = currentLang == 'vi'
              ? 'Phê duyệt chuẩn bị'
              : '準備承認';
          final homeText = currentLang == 'vi' ? 'Trang chủ' : 'ホーム';
          final createEvaluationText = currentLang == 'vi'
              ? 'Lập đánh giá'
              : '評価作成';
          final fillEvaluationText = currentLang == 'vi'
              ? 'Điền đánh giá'
              : '評価記入';
          final approvalText = currentLang == 'vi' ? 'Phê duyệt' : '承認';

          if (subMenu == userManagementText) {
            widget.changeBody(MasterUser());
          } else if (subMenu == pthcInfoText) {
            widget.changeBody(MasterPTHC());
          } else if (subMenu == indefiniteContractText) {
            if (title == createEvaluationText) {
              widget.changeBody(TwoContractScreen());
            } else if (title == fillEvaluationText) {
              widget.changeBody(FillTwoScreen());
            } else if (title == approvalText) {
              widget.changeBody(ApprovalTwoScreen());
            }
          } else if (subMenu == trialContractText) {
            if (title == createEvaluationText) {
              widget.changeBody(ApprenticeContractScreen());
            } else if (title == fillEvaluationText) {
              widget.changeBody(FillApprenticeScreen());
            } else if (title == approvalText) {
              widget.changeBody(ApprovalTrialScreen());
            }
          } else if (subMenu == preparationApprovalText) {
            widget.changeBody(ApprovalPrepartionScreen());
          } else if (subMenu == homeText) {
            widget.changeBody(HomeScreen(changeBody: (newPage) {}));
          } else {
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
        title: Text('welcome'.tr(), style: TextStyle(color: Colors.white)),
        subtitle: Text(
          "Nguyễn Duy Khánh",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
  void expandOrShrinkDrawer() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }
}
