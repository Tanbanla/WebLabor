import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/class/ChartYear.dart';

class ContractStatsScreen extends StatefulWidget {
  final String? vaitro;
  final String? section;
  const ContractStatsScreen({
    super.key,
    required this.vaitro,
    required this.section,
  });
  @override
  // ignore: library_private_types_in_public_api
  _ContractStatsScreenState createState() => _ContractStatsScreenState();
}

class _ContractStatsScreenState extends State<ContractStatsScreen> {
  List<ChartYear> monthlyData = <ChartYear>[];
  int _selectedYear = DateTime.now().year;
  bool _showNew = true;
  bool _showWaitingApprove = true;
  bool _showApproved = true;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData(vaitro: widget.vaitro, section: widget.section);
  }

  Future<void> _fetchData({String? vaitro, String? section}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    String linkApi = '';
    if (vaitro == 'Per' || vaitro == 'Admin') {
      linkApi = '${Common.API}${Common.ContractTotalByYear}$_selectedYear';
    } else {
      linkApi =
          '${Common.API}${Common.ContractTotalByYear}$_selectedYear/$section';
    }
    try {
      final response = await http.get(Uri.parse(linkApi));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          if (mounted) {
            setState(() {
              monthlyData = (jsonData['data'] as List).map((item) {
                return ChartYear.fromJson(item);
              }).toList();
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _error = jsonData['message'] ?? 'Failed to load data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return SizedBox(
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
                          '${tr('titleChart')} $_selectedYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            DropdownButton<int>(
                              value: _selectedYear,
                              items: List.generate(5, (index) {
                                int year = DateTime.now().year - index;
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedYear = value;
                                  });
                                  _fetchData();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilterChip(
                          label: Text(tr('New')),
                          selected: _showNew,
                          onSelected: (selected) {
                            setState(() {
                              _showNew = selected;
                            });
                          },
                          selectedColor: Colors.blue,
                          checkmarkColor: Colors.white,
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text(tr('ChoDuyet')),
                          selected: _showWaitingApprove,
                          onSelected: (selected) {
                            setState(() {
                              _showWaitingApprove = selected;
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text(tr("DaDuyet")),
                          selected: _showApproved,
                          onSelected: (selected) {
                            setState(() {
                              _showApproved = selected;
                            });
                          },
                          selectedColor: Colors.green,
                          checkmarkColor: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildChartContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    if (_isLoading) {
      return SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(_error!, style: TextStyle(color: Colors.red)),
        ),
      );
    }

    if (monthlyData.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(child: Text('Sorry, No data 🥲')),
      );
    }

    return SizedBox(
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
                  if (index >= 0 && index < monthlyData.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Th${monthlyData[index].month}',
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateInterval(),
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: (monthlyData.length).toDouble() - 1,
          minY: 0,
          maxY: _getMaxYValue(),
          lineBarsData: _buildLineBarsData(),
        ),
      ),
    );
  }

  double _calculateInterval() {
    double maxY = _getMaxYValue();
    if (maxY <= 10) return 1;
    if (maxY <= 50) return 5;
    if (maxY <= 100) return 10;
    if (maxY <= 500) return 50;
    return 100;
  }

  double _getMaxYValue() {
    if (monthlyData.isEmpty) return 10;

    double max = 0;
    for (var data in monthlyData) {
      if (_showNew && data.totalNew! > max) max = data.totalNew! as double;
      if (_showWaitingApprove && data.totalWaitingApprove! > max) {
        max = data.totalWaitingApprove! as double;
      }
      if (_showApproved && data.totalApproved! > max) {
        max = data.totalApproved! as double;
      }
    }
    return max + 10;
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> lineBarsData = [];

    if (_showNew) {
      lineBarsData.add(
        LineChartBarData(
          spots: monthlyData.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.totalNew?.toInt() as double,
            );
          }).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
      );
    }
    if (_showWaitingApprove) {
      lineBarsData.add(
        LineChartBarData(
          spots: monthlyData.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.totalWaitingApprove?.toInt() as double,
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

    if (_showApproved) {
      lineBarsData.add(
        LineChartBarData(
          spots: monthlyData.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.totalApproved! as double,
            );
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
    return lineBarsData;
  }
}
