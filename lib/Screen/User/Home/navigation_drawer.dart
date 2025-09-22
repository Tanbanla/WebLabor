import 'package:flutter/material.dart';
import 'package:web_labor_contract/API/Controller/PTHC_controller.dart';
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
import 'package:web_labor_contract/Screen/User/LoginScreen/sign_in_screen.dart';
import 'package:web_labor_contract/Screen/User/Report/report_apprentice.dart';
import 'package:web_labor_contract/Screen/User/Report/report_two.dart';
import 'package:web_labor_contract/class/CMD.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:web_labor_contract/main.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // for platform check
import 'package:universal_html/html.dart'
    as html; // to manipulate browser history

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Widget _currentBody; // Sử dụng late thay vì khởi tạo ngay
  final DashboardControllerPTHC controller = Get.put(DashboardControllerPTHC());
  final path = Uri.base.path;
  @override
  void initState() {
    super.initState();
    _currentBody = _getBodyForPath(path);
  }

  Widget _getBodyForPath(String path) {
    switch (path) {
      case '/two':
        return TwoContractScreen();
      case '/apprentice':
        return ApprenticeContractScreen();
      case '/filltwo':
        return FillTwoScreen();
      case '/fillapprentice':
        return FillApprenticeScreen();
      case '/approvaltwo':
        return ApprovalTwoScreen();
      case '/approvaltrial':
        return ApprovalTrialScreen();
      case '/approvalpreparation':
        return ApprovalPrepartionScreen();
      case '/reporttwo':
        return ReportTwoScreen();
      case '/reportapprentice':
        return ReportApprentice();
      case '/masteruser':
        return MasterUser();
      case '/masterpthc':
        return MasterPTHC();
      default:
        return HomeScreen(onNavigate: _changeBody);
    }
  }

  void _changeBody(Widget newBody, {String? newPath}) {
    if (!mounted) return;
    setState(() {
      _currentBody = newBody;
      if (newPath != null) {
        _resetUrlPath();
      }
    });
  }

  void _resetUrlPath() {
    if (!kIsWeb) return;
    try {
      // Đưa URL về origin (không path) mà không reload trang
      final origin = html.window.location.origin;
      // origin giữ dạng http://localhost:54364 (không thêm path)
      html.window.history.replaceState(null, '', origin);
    } catch (_) {
      // fallback: bỏ qua nếu không chỉnh được history
    }
  }

  //
  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
    controller.fetchPTHCSectionList(authState.user!.chREmployeeId.toString());
    // Nếu truy cập trực tiếp bằng deep-link (ví dụ /two) sau khi load xong sẽ reset URL về root.
    // Thực hiện một lần ở frame đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && Uri.base.path.isNotEmpty && Uri.base.path != '/') {
        _resetUrlPath();
      }
    });
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageNotifier.notifier,
      builder: (context, locale, child) {
        return Scaffold(
          appBar: appBar(),
          body: _currentBody,
          drawer: ComplexDrawer(changeBody: _changeBody, context: context),
          drawerScrimColor: Colors.transparent,
          backgroundColor: Colors.white,
        );
      },
    );
  }

  AppBar appBar() {
    return AppBar(
      iconTheme: IconTheme.of(context).copyWith(color: Colors.white),
      title: Text(
        tr('appTitle'),
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
                  LanguageNotifier.changeLanguage(Locale('ja'));
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
                  LanguageNotifier.changeLanguage(Locale('vi'));
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

  const ComplexDrawer({
    Key? key,
    required this.changeBody,
    required this.context,
  }) : super(key: key);

  @override
  _ComplexDrawerState createState() => _ComplexDrawerState();
}

class _ComplexDrawerState extends State<ComplexDrawer> {
  int selectedIndex = -1; //dont set it to 0
  bool isExpanded = false;
  late AuthState authState; //= Provider.of<AuthState>(context, listen: true);
  @override
  void initState() {
    super.initState();
    // Không thể truy cập context ở đây vì widget chưa được build
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authState = Provider.of<AuthState>(context, listen: true); // Khởi tạo ở đây
  }

  List<CDM> get allCdms {
    return [
      CDM(Icons.home, tr('home'), [tr('home')]),
      CDM(Icons.grid_view, tr("master"), [
        tr("userManagement"),
        tr("pthcInfo"),
        tr("screenList"),
      ]),
      CDM(Icons.subscriptions, tr('createEvaluation'), [
        tr("trialContract"),
        tr("indefiniteContract"),
        tr("preparationApproval"),
      ]),
      CDM(Icons.explore, tr("fillEvaluation"), [
        tr("trialContract"),
        tr("indefiniteContract"),
      ]),
      CDM(Icons.markunread_mailbox, tr("approval"), [
        tr("trialContract"),
        tr("indefiniteContract"),
      ]),
      CDM(Icons.pie_chart, tr("report"), [
        tr("trialContract"),
        tr("indefiniteContract"),
      ]),
      CDM(Icons.settings, tr("settings"), []),
    ];
  }

  // Lấy danh sách menu theo quyền
  List<CDM> get cdms {
    final userGroup = authState.user?.chRGroup?.toString() ?? '';

    switch (userGroup) {
      case 'Admin':
        return allCdms; // Admin có tất cả quyền
      // Quyen cua PER
      case 'Per':
        return allCdms
            .where(
              (cdm) => cdm.title != tr("master") && cdm.title != tr("approval"),
            )
            .toList();
      case 'Chief Per':
        return allCdms.where((cdm) => cdm.title != tr("master")).toList();
      // Quyen dien danh gia cua phong ban
      case 'PTHC':
      case 'Technician':
      case 'Staff':
      case 'Operator':
      case 'Supervisor':
      case 'Leader':
        return allCdms
            .where(
              (cdm) =>
                  cdm.title == tr("fillEvaluation") || cdm.title == tr('home'),
            )
            .toList();
      // Quyen phe duyet
      case 'Chief Section':
      case 'Section Manager':
      case 'General Director':
      case 'Dept Manager':
      case 'Director':
        return allCdms
            .where(
              (cdm) => cdm.title == tr("approval") || cdm.title == tr('home'),
            )
            .toList();
      default:
        return [allCdms.first]; // Chỉ hiển thị trang chủ nếu không có quyền
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: row());
  }

  Widget row() {
    return Row(
      children: [
        // isExpanded ? blackIconTiles()  : blackIconMenu(),
        // invisibleSubMenus(),
        if (isExpanded) ...[
          blackIconMenu(),
          invisibleSubMenus(),
        ] else
          blackIconTiles(),
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
          leading: Image.asset('assets/icons/icon_lc.png'),
          title: Text(
            tr('appTitle'),
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
      width: !isExpanded ? 0 : 200,
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
          child: Image.asset('assets/icons/icon_lc.png'),
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
              ? 'Hợp đồng xác định thời hạn'
              : '期限付き契約';
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
          final reportText = currentLang == 'vi' ? 'Báo cáo' : 'レポート';
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
            } else if (title == reportText) {
              widget.changeBody(ReportTwoScreen());
            }
          } else if (subMenu == trialContractText) {
            if (title == createEvaluationText) {
              widget.changeBody(ApprenticeContractScreen());
            } else if (title == fillEvaluationText) {
              widget.changeBody(FillApprenticeScreen());
            } else if (title == approvalText) {
              widget.changeBody(ApprovalTrialScreen());
            } else if (title == reportText) {
              widget.changeBody(ReportApprentice());
            }
          } else if (subMenu == preparationApprovalText) {
            widget.changeBody(ApprovalPrepartionScreen());
          } else if (subMenu == homeText) {
            widget.changeBody(HomeScreen(onNavigate: widget.changeBody));
          } else {
            widget.changeBody(HomeScreen(onNavigate: widget.changeBody));
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
            //ảnh assets/img/signin.png
            image: AssetImage('assets/icons/icon_lc.png'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget accountTile() {
    final authState = Provider.of<AuthState>(context, listen: true);
    return Container(
      color: Common.primaryColor,
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              leading: accountButton(usePadding: false),
              title: Text(tr('welcome'), style: TextStyle(color: Colors.white)),
              subtitle: Text(
                authState.user?.nvchRNameId.toString() ?? tr('NotLogin'),
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: tr('LogOut'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr('LogOut1')),
                  content: Text(tr('LogOut2')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr('Cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        tr('LogOut'),
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await authState.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignInScreen(),
                    ), // Thay SignInScreen() bằng widget màn hình login của bạn
                    (Route<dynamic> route) =>
                        false, // Xóa toàn bộ stack navigation
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('LogOut faile: ${e.toString()}')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void expandOrShrinkDrawer() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }
}
