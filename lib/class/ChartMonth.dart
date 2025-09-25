class ChartMonth {
  final int totalApprenticeNew;
  final int totalTwoYearNew;
  final int totalApprenticeWaitingApprove;
  final int totalTwoYearWaitingApprove;
  final int totalBothApproved;
  final int totalApprenticeStatus34;
  final int totalTwoYearStatus34;

  ChartMonth({
    required this.totalApprenticeNew,
    required this.totalTwoYearNew,
    required this.totalApprenticeWaitingApprove,
    required this.totalTwoYearWaitingApprove,
    required this.totalBothApproved,
    required this.totalApprenticeStatus34,
    required this.totalTwoYearStatus34,
  });

  factory ChartMonth.fromJson(Map<String, dynamic> json) {
    return ChartMonth(
      totalApprenticeNew: json['totalApprenticeNew'] ?? 0,
      totalTwoYearNew: json['totalTwoYearNew'] ?? 0,
      totalApprenticeWaitingApprove: json['totalApprenticeWaitingApprove'] ?? 0,
      totalTwoYearWaitingApprove: json['totalTwoYearWaitingApprove'] ?? 0,
      totalBothApproved: json['totalBothApproved'] ?? 0,
      totalApprenticeStatus34: json['totalApprenticeStatus34'] ?? 0,
      totalTwoYearStatus34: json['totalTwoYearStatus34'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalApprenticeNew': totalApprenticeNew,
      'totalTwoYearNew': totalTwoYearNew,
      'totalApprenticeWaitingApprove': totalApprenticeWaitingApprove,
      'totalTwoYearWaitingApprove': totalTwoYearWaitingApprove,
      'totalBothApproved': totalBothApproved,
      'totalApprenticeStatus34': totalApprenticeStatus34,
      'totalTwoYearStatus34': totalTwoYearStatus34,
    };
  }

  static empty() {}
}
