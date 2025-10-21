import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'
show rootBundle; // For loading asset bytes
// Conditional import: real implementation on web, stub elsewhere
import 'package:web_labor_contract/util/download_manual_stub.dart'
    if (dart.library.html) 'package:web_labor_contract/util/download_manual_web.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/class/CMD.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:web_labor_contract/main.dart';
// Removed kIsWeb and html imports after router refactor
import 'package:go_router/go_router.dart';
import '../../../router.dart';

class MenuScreen extends StatelessWidget {
  final Widget child;
  const MenuScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    //final authState = Provider.of<AuthState>(context, listen: true);
    // final authState = Provider.of<AuthState>(context, listen: true);
    // Get.put(
    //   DashboardControllerPTHC(),
    // ).fetchPTHCSectionList(authState.user!.chREmployeeId.toString());
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageNotifier.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          appBar: appBar(context),
          body: child,
          drawer: ComplexDrawer(context: context),
          drawerScrimColor: Colors.transparent,
          backgroundColor: Colors.white,
        );
      },
    );
  }

  AppBar appBar(BuildContext context) => AppBar(
    iconTheme: IconTheme.of(context).copyWith(color: Colors.white),
    title: Text(tr('appTitle'), style: TextStyle(color: Colors.white)),
    backgroundColor: Common.primaryColor,
    actions: [
      // Manual (LCE.pptx) download button
      TextButton.icon(
        onPressed: () => _downloadManual(context),
        icon: Icon(Icons.download, color: Colors.white, size: 20),
        label: Text(
          tr('Manual'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Image.asset(
                'assets/img/jp.png',
                height: 24,
                width: 40,
                fit: BoxFit.cover,
              ),
              onPressed: () {
                context.setLocale(Locale('ja'));
                LanguageNotifier.changeLanguage(Locale('ja'));
              },
            ),
            IconButton(
              icon: Image.asset(
                'assets/img/vn.jpg',
                height: 24,
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

// Helper method added to MenuScreen (outside class scope previously) moved inside extension-like pattern
extension _ManualDownload on MenuScreen {
  Future<void> _downloadManual(BuildContext context) async {
    const assetPath = 'assets/templates/LCES.pptx';
    const downloadName = 'LCES - hướng dẫn sử dụng hệ thống.pptx';
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      if (kIsWeb) {
        await saveFileWeb(bytes, downloadName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Download') + ' OK: $downloadName')),
        );
      } else {
        // Non-web platforms: not yet implemented fully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download chỉ hỗ trợ trên Web hiện tại.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download lỗi: $e')));
    }
  }
}

class ComplexDrawer extends StatefulWidget {
  final BuildContext context;

  const ComplexDrawer({Key? key, required this.context}) : super(key: key);

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
        return allCdms
            .where(
              (cdm) =>
                  cdm.title == tr("fillEvaluation") || cdm.title == tr('home') || cdm.title == tr("report"),
            )
            .toList();
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
            context.go(AppRoutes.masterUser);
          } else if (subMenu == pthcInfoText) {
            context.go(AppRoutes.masterPthc);
          } else if (subMenu == indefiniteContractText) {
            if (title == createEvaluationText) {
              context.go(AppRoutes.twoContract);
            } else if (title == fillEvaluationText) {
              context.go(AppRoutes.fillTwo);
            } else if (title == approvalText) {
              context.go(AppRoutes.approvalTwo);
            } else if (title == reportText) {
              context.go(AppRoutes.reportTwo);
            }
          } else if (subMenu == trialContractText) {
            if (title == createEvaluationText) {
              context.go(AppRoutes.apprenticeContract);
            } else if (title == fillEvaluationText) {
              context.go(AppRoutes.fillApprentice);
            } else if (title == approvalText) {
              context.go(AppRoutes.approvalTrial);
            } else if (title == reportText) {
              context.go(AppRoutes.reportApprentice);
            }
          } else if (subMenu == preparationApprovalText) {
            context.go(AppRoutes.approvalPreparation);
          } else if (subMenu == homeText) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.home);
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
                  if (!mounted) return;
                  context.go(AppRoutes.signIn);
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
