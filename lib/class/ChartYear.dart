class ChartYear {
  String? month;
  int? totalNew;
  int? totalWaitingApprove;
  int? totalApproved;

  ChartYear({this.month, this.totalNew, this.totalWaitingApprove, this.totalApproved});

  ChartYear.fromJson(Map<String, dynamic> json) {
    if(json["month"] is String) {
      month = json["month"];
    }
    if(json["totalNew"] is int) {
      totalNew = json["totalNew"];
    }
    if(json["totalWaitingApprove"] is int) {
      totalWaitingApprove = json["totalWaitingApprove"];
    }
    if(json["totalApproved"] is int) {
      totalApproved = json["totalApproved"];
    }
  }

  static List<ChartYear> fromList(List<Map<String, dynamic>> list) {
    return list.map(ChartYear.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["month"] = month;
    _data["totalNew"] = totalNew;
    _data["totalWaitingApprove"] = totalWaitingApprove;
    _data["totalApproved"] = totalApproved;
    return _data;
  }
}