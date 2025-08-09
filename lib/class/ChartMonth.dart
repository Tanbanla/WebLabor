class ChartMonth {
  final int totalApprenticeNew;
  final int totalTwoYearNew;
  final int totalApprenticeWaitingApprove;
  final int totalTwoYearWaitingApprove;
  final int totalBothApproved;

  ChartMonth({
    required this.totalApprenticeNew,
    required this.totalTwoYearNew,
    required this.totalApprenticeWaitingApprove,
    required this.totalTwoYearWaitingApprove,
    required this.totalBothApproved,
  });

  factory ChartMonth.fromJson(Map<String, dynamic> json) {
    return ChartMonth(
      totalApprenticeNew: json['totalApprenticeNew'] ?? 0,
      totalTwoYearNew: json['totalTwoYearNew'] ?? 0,
      totalApprenticeWaitingApprove: json['totalApprenticeWaitingApprove'] ?? 0,
      totalTwoYearWaitingApprove: json['totalTwoYearWaitingApprove'] ?? 0,
      totalBothApproved: json['totalBothApproved'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalApprenticeNew': totalApprenticeNew,
      'totalTwoYearNew': totalTwoYearNew,
      'totalApprenticeWaitingApprove': totalApprenticeWaitingApprove,
      'totalTwoYearWaitingApprove': totalTwoYearWaitingApprove,
      'totalBothApproved': totalBothApproved,
    };
  }

  static empty() {}
}