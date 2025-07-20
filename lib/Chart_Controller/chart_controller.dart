import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ContractStatsScreen extends StatefulWidget {
  @override
  _ContractStatsScreenState createState() => _ContractStatsScreenState();
}

class _ContractStatsScreenState extends State<ContractStatsScreen> {
  final List<MonthlyContractData> monthlyData = [
    MonthlyContractData(month: 'Th1', signed: 1500, unsigned: 500),
    MonthlyContractData(month: 'Th2', signed: 1800, unsigned: 700),
    MonthlyContractData(month: 'Th3', signed: 2200, unsigned: 300),
    MonthlyContractData(month: 'Th4', signed: 2500, unsigned: 200),
    MonthlyContractData(month: 'Th5', signed: 2000, unsigned: 800),
    MonthlyContractData(month: 'Th6', signed: 2800, unsigned: 400),
    MonthlyContractData(month: 'Th7', signed: 3000, unsigned: 200),
    MonthlyContractData(month: 'Th8', signed: 2600, unsigned: 600),
    MonthlyContractData(month: 'Th9', signed: 2400, unsigned: 300),
    MonthlyContractData(month: 'Th10', signed: 2900, unsigned: 100),
    MonthlyContractData(month: 'Th11', signed: 3200, unsigned: 0),
    MonthlyContractData(month: 'Th12', signed: 3500, unsigned: 200),
  ];

  int _selectedYear = DateTime.now().year;
  bool _showSigned = true;
  bool _showUnsigned = true;

  @override
  Widget build(BuildContext context) {
        Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: 500,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Biểu đồ hợp đồng năm $_selectedYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            FilterChip(
                              label: Text('Đã ký'),
                              selected: _showSigned,
                              onSelected: (selected) {
                                setState(() {
                                  _showSigned = selected;
                                });
                              },
                              selectedColor: Colors.green,
                              checkmarkColor: Colors.white,
                            ),
                            SizedBox(width: 8),
                            FilterChip(
                              label: Text('Chưa ký'),
                              selected: _showUnsigned,
                              onSelected: (selected) {
                                setState(() {
                                  _showUnsigned = selected;
                                });
                              },
                              selectedColor: Colors.orange,
                              checkmarkColor: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(enabled: true),
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 &&
                                      index < monthlyData.length) {
                                    return Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        monthlyData[index].month,
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                reservedSize: 30,
                                interval: 1
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1000,
                                reservedSize: 40,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          minX: 0,
                          maxX: (monthlyData.length).toDouble() -1,
                          minY: 0,
                          maxY: _getMaxYValue(),
                          lineBarsData: _buildLineBarsData(),
                        ),
                      ),
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

  double _getMaxYValue() {
    double max = 0;
    for (var data in monthlyData) {
      if (_showSigned && data.signed > max) max = data.signed.toDouble();
      if (_showUnsigned && data.unsigned > max) max = data.unsigned.toDouble();
    }
    return max + 10;
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> lineBarsData = [];

    if (_showSigned) {
      lineBarsData.add(
        LineChartBarData(
          spots: monthlyData.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.signed.toDouble());
          }).toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.3),
          ),
        ),
      );
    }

    if (_showUnsigned) {
      lineBarsData.add(
        LineChartBarData(
          spots: monthlyData.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.unsigned.toDouble(),
            );
          }).toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.3),
          ),
        ),
      );
    }

    return lineBarsData;
  }
}

class MonthlyContractData {
  final String month;
  final int signed;
  final int unsigned;

  MonthlyContractData({
    required this.month,
    required this.signed,
    required this.unsigned,
  });
}
