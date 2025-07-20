import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_labor_contract/Chart_Controller/chart_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:iconsax/iconsax.dart';

class HomeScreen extends StatefulWidget {
  final Function(Widget) changeBody;

  const HomeScreen({super.key, required this.changeBody});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dữ liệu mẫu - bạn có thể thay thế bằng dữ liệu thực từ API
  final int contractsToApprove = 26;
  final int contractsToApprove2Years = 32;
  final int approvedThisMonth = 29;
  final int signedContracts = 22; // Hợp đồng đã ký
  final int unsignedContracts = 7; // Hợp đồng chưa ký

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Common.grayColor.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông báo',
              style: TextStyle(
                color: Common.primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Hàng thứ nhất: Thống kê hợp đồng
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildContractCard(
                    icon: Iconsax.document1,
                    color: Colors.red,
                    title: 'Số hợp đồng học nghề, thử việc cần duyệt',
                    value: contractsToApprove.toString(),
                    width: size.width > 600 ? 500 : size.width * 0.75,
                  ),
                  const SizedBox(width: 20),
                  _buildContractCard(
                    icon: Iconsax.document_copy,
                    color: Colors.orange,
                    title: 'Số hợp đồng 2 năm cần duyệt',
                    value: contractsToApprove2Years.toString(),
                    width: size.width > 600 ? 500 : size.width * 0.75,
                  ),
                  const SizedBox(width: 20),
                  _buildContractCard(
                    icon: Iconsax.document4,
                    color: Colors.green,
                    title: 'Số hợp đồng đã duyệt tháng này',
                    value: approvedThisMonth.toString(),
                    width: size.width > 600 ? 500 : size.width * 0.75,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            ContractStatsScreen(),
            
            // Biểu đồ tròn
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Tỉ lệ hợp đồng đã ký',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: signedContracts.toDouble(),
                              title: '${(signedContracts/(signedContracts+unsignedContracts)*100).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.orange,
                              value: unsignedContracts.toDouble(),
                              title: '${(unsignedContracts/(signedContracts+unsignedContracts)*100).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend(color: Colors.green, text: 'Đã ký'),
                        const SizedBox(width: 20),
                        _buildLegend(color: Colors.orange, text: 'Chưa ký'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(icon: icon, color: color, onPressed: () {}),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: color, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
