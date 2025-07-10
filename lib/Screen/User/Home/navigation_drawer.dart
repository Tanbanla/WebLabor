import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/class/CMD.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: ComplexDrawer(),
      drawerScrimColor: Colors.blueGrey.withOpacity(.3),
      backgroundColor: Common.grayColor.withOpacity(.5),
    );
  }
}
Widget appBar(){
  return AppBar(
    title: 
    Text('LABOR CONTRACT EVALUATION',style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Common.primaryColor,
      ),
    ),
    backgroundColor: Common.greenColor.withOpacity(.3),

  );
}
class ComplexDrawer extends StatefulWidget {
  const ComplexDrawer({super.key});

  @override
  State<ComplexDrawer> createState() => _ComplexDrawerState();
}

class _ComplexDrawerState extends State<ComplexDrawer> {
  int selectedIndex = -1;
  @override
  Widget build(BuildContext context) {
    double widget = MediaQuery.of(context).size.width;
    return Container(
      width: widget/2,
      child: row(),
    );
  }
  Widget row(){
    return Row(
      children: [
        blackIconMenu(),
        invisibleSubMenus(),
      ],
    );
  }

  Widget blackIconMenu() {
      return Container(
        width: 100,
        color: Common.primaryColor,
        child: ListView.builder(
          itemCount: icons.length,
          itemBuilder: (context , index){
            return InkWell(
              onTap: () {
                setState((){
                  selectedIndex = index;
                });
              },
              child: Container(
                height:  45,
                alignment: Alignment.center,
                child: Icon(icons[index].icon, color: Colors.white,),
              ),
            );
          }
        ),
      );
  }
  Widget invisibleSubMenus() {
      return Container(
        width: 200,
        color: Color.fromARGB(255, 119, 201, 146).withOpacity(0.2),
        child: ListView.builder(
          itemCount: icons.length,
          itemBuilder: (context , index){
            CDM cmd = icons[index];
            bool selected = selectedIndex == index;
            bool isvaule = selected && cmd.submenus.isNotEmpty;
            return subMenuWidget(cmd.title, cmd.submenus, isvaule);
          }
        ),
      );
  }
  Widget subMenuWidget(String title, List<String> submenus, bool selected){
    return AnimatedContainer(
      duration: Duration(seconds: 1),
      height: selected ? 200 : 45,
      decoration: BoxDecoration(
        color: selected ?  Colors.white60 : Colors.transparent,
        borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))
      ),
      color: Common.primaryColor.withOpacity(.5),
      child: ListView.builder(
        padding: EdgeInsets.all(6),
        itemCount: selected ? submenus.length : 0,
        itemBuilder: (context, index){
          String subMenu = submenus[index];
          return InkWell(
            onTap: () {
              
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(subMenu, style: TextStyle(color: Common.primaryColor,fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      ),
    );
  }
  Widget isSubMenuWidget(){
    return Container(
      height:  45,
      color: Colors.green,
    );
  }
}
List<CDM> icons = [
  CDM(Icons.grid_view, "Dashboard", []),
  CDM(Icons.subscriptions, "Dashboard1", []),
  CDM(Icons.markunread_mailbox, "Dashboard2", []),
  CDM(Icons.pie_chart, "Dashboard3", ["Vuong","Tron","Tam giac"]),
  CDM(Icons.trending_down, "Dashboard4", []),
  CDM(Icons.power, "Dashboard5", []),
];