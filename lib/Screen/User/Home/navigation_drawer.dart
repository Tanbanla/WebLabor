import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Screen/User/Master/master_pthc.dart';
import 'package:web_labor_contract/class/CMD.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: body(),
      drawer: ComplexDrawer(),
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
      backgroundColor: Common.primaryColor.withOpacity(0.6),
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
        child: MasterPTHC(),
      ),
    );
  }
}

class ComplexDrawer extends StatefulWidget {
  const ComplexDrawer({Key? key}) : super(key: key);

  @override
  _ComplexDrawerState createState() => _ComplexDrawerState();
}

class _ComplexDrawerState extends State<ComplexDrawer> {
  int selectedIndex = -1; //dont set it to 0

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
                    return sMenuButton(subMenu, false);
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

  Widget subMenuWidget(List<String> submenus, bool isValidSubMenu) {
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
          return sMenuButton(subMenu, index == 0);
        },
      ),
    );
  }

  Widget sMenuButton(String subMenu, bool isTitle) {
    return InkWell(
      onTap: () {
        //handle the function
        //if index==0? donothing: doyourlogic here
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
        title: Text("Welocome", style: TextStyle(color: Colors.white)),
        subtitle: Text(
          "Nguyễn Duy Khánh",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  static List<CDM> cdms = [
    CDM(Icons.grid_view, "Master", [
      "Quản lý User",
      "Thông tin PTHC",
      "Danh sách màn hình",
    ]),
    CDM(Icons.subscriptions, "Lập đánh giá", [
      "Hợp đồng thử nghề & học việc",
      "Hợp đồng không xác định thời gian",
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
    // CDM(Icons.trending_up, "Chart", []),
    // CDM(Icons.power, "Plugins", []),
    CDM(Icons.settings, "Setting", []),
  ];

  void expandOrShrinkDrawer() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }
}
