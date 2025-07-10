import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Screen/User/LoginScreen/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Common.grayColor.withOpacity(0.1),
      body: Row(
        children: [
          Column(
            children: [
              Container(
                height: size.height,
                width:  350,
                padding:  EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 119, 201, 146).withOpacity(0.2),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'LABOR CONTRACT EVALUATION',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Common.primaryColor,
                      ),
                    ),
                    // Item 1
                    _buildMenuItem(
                      icon: Icons.dashboard,
                      label: 'Master',
                      onPressed: () {
                        // Xử lý khi nhấn vào Master
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                      },
                    ),
                    
                    // Item 2
                    _buildMenuItem(
                      icon: Icons.assessment,
                      label: 'Lập danh sách đánh giá',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                      },
                    ),
                    // Item 3
                    _buildMenuItem(
                      icon: Icons.access_alarm,
                      label: 'Đánh giá',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                      },
                    ),
                    // Item 4
                    _buildMenuItem(
                      icon: Icons.access_time,
                      label: 'Phê duyệt',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                      },
                    ),
                    // Item 5
                    _buildMenuItem(
                      icon: Icons.accessibility_sharp,
                      label: 'Báo cáo',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                      },
                    ),
                  ],
                ),
              ),
              )
            ],
          ),
          Column(),
        ],
      ),
    );
  }
}
// Hàm phụ trợ để tạo các mục menu
Widget _buildMenuItem({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14, // Tăng kích thước chữ
                fontWeight: FontWeight.w600, // Độ đậm vừa phải
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}