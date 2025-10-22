import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Chart_Controller/chart_controller.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_labor_contract/class/ChartMonth.dart';
import 'package:web_labor_contract/main.dart';
import 'package:web_labor_contract/router.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String)? onNavigate;
  const HomeScreen({Key? key, this.onNavigate}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến lưu trữ dữ liệu từ API
  late ChartMonth contractStats;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchContractStatistics();
  }

  Future<void> _fetchContractStatistics() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    String linkApi = '';
    if (authState.user!.chRGroup.toString() == 'Per' ||
        authState.user!.chRGroup == 'Admin') {
      linkApi =
          '${Common.API}${Common.ContractTotalByMonth}${DateTime.now().month}/${DateTime.now().year}';
    } else {
      linkApi =
          '${Common.API}${Common.ContractTotalByMonth}${DateTime.now().month}/${DateTime.now().year}/${authState.user!.chRSecCode}';
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(linkApi));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            final jsonData = data['data'] as Map<String, dynamic>;
            contractStats = ChartMonth.fromJson(jsonData);
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
    Size size = MediaQuery.of(context).size;
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageNotifier.notifier,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: Common.grayColor.shade100,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Notification'),
                  style: TextStyle(
                    color: Common.primaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage.isNotEmpty)
                  Center(
                    child: Text(
                      'Error: $errorMessage',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else ...[
                  // Hàng thứ nhất: Thống kê hợp đồng
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            _buildContractCard(
                              icon: Iconsax.document1,
                              color: Colors.brown,
                              title: tr('HDHN'),
                              value: contractStats.totalApprenticeWaitingApprove
                                  .toString(),
                              width: size.width > 600 ? 500 : size.width * 0.75,
                              onTap: () {
                                if (authState.user!.chRGroup.toString() ==
                                    'Chief') {
                                  context.go(AppRoutes.fillApprentice);
                                } else if (authState.user!.chRGroup
                                            .toString() ==
                                        'Chief Per' ||
                                    authState.user!.chRGroup.toString() ==
                                        'Admin') {
                                  context.go(AppRoutes.approvalPreparation);
                                } else {
                                  context.go(AppRoutes.approvalTrial);
                                }
                                //context.go(AppRoutes.approvalTrial);
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildContractCard(
                              icon: Iconsax.document_cloud,
                              color: Colors.blue,
                              title: tr('HDHVCanDuyet'),
                              value: contractStats.totalApprenticeStatus34
                                  .toString(),
                              width: size.width > 600 ? 500 : size.width * 0.75,
                              onTap: () {
                                context.go(AppRoutes.fillApprentice);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            _buildContractCard(
                              icon: Iconsax.document_copy,
                              color: Colors.orange,
                              title: tr('HD2N'),
                              value: contractStats.totalTwoYearWaitingApprove
                                  .toString(),
                              width: size.width > 600 ? 500 : size.width * 0.75,
                              onTap: () {
                                if (authState.user!.chRGroup.toString() ==
                                    'Chief') {
                                  context.go(AppRoutes.fillTwo);
                                } else if (authState.user!.chRGroup
                                            .toString() ==
                                        'Chief Per' ||
                                    authState.user!.chRGroup.toString() ==
                                        'Admin') {
                                  context.go(AppRoutes.approvalPreparation);
                                } else {
                                  context.go(AppRoutes.approvalTwo);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildContractCard(
                              icon: Iconsax.document_copy,
                              color: Colors.purple,
                              title: tr('HDXDCCanDuyet'),
                              value: contractStats.totalTwoYearStatus34
                                  .toString(),
                              width: size.width > 600 ? 500 : size.width * 0.75,
                              onTap: () {
                                context.go(AppRoutes.fillTwo);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        _buildContractCard(
                          icon: Iconsax.document4,
                          color: Colors.green,
                          title: tr('ThongBaoDaDuyet'),
                          value: contractStats.totalBothApproved.toString(),
                          width: size.width > 600 ? 500 : size.width * 0.75,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  ContractStatsScreen(
                    vaitro: authState.user!.chRGroup,
                    section: authState.user!.chRSecCode,
                  ),

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
                            tr('TyLeHoanThanh'),
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
                                    value: (contractStats.totalBothApproved)
                                        .toDouble(),
                                    title:
                                        '${((contractStats.totalBothApproved) / (contractStats.totalApprenticeWaitingApprove + contractStats.totalTwoYearWaitingApprove + contractStats.totalBothApproved) * 100).toStringAsFixed(1)}%',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.orange,
                                    value:
                                        (contractStats
                                                    .totalApprenticeWaitingApprove +
                                                contractStats
                                                    .totalTwoYearWaitingApprove)
                                            .toDouble(),
                                    title:
                                        '${((contractStats.totalApprenticeWaitingApprove + contractStats.totalTwoYearWaitingApprove) / (contractStats.totalApprenticeWaitingApprove + contractStats.totalTwoYearWaitingApprove + contractStats.totalBothApproved) * 100).toStringAsFixed(1)}%',
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
                              _buildLegend(
                                color: Colors.green,
                                text: tr('DaDuyet'),
                              ),
                              const SizedBox(width: 20),
                              _buildLegend(
                                color: Colors.orange,
                                text: tr('ChoDuyet'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContractCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required double width,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            // Icon(icon, color: color, size: 42),
            const SizedBox(height: 42),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
