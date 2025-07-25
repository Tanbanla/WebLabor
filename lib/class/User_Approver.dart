class ApproverUser {
  String? chREmployeeId;
  String? chREmployeeName;
  String? chREmployeeAdid;
  String? chREmployeeMail;
  String? chRPosition;
  String? chRPositionGroup;

  ApproverUser({this.chREmployeeId, this.chREmployeeName, this.chREmployeeAdid, this.chREmployeeMail, this.chRPosition, this.chRPositionGroup});

  ApproverUser.fromJson(Map<String, dynamic> json) {
    if(json["chR_EMPLOYEE_ID"] is String) {
      chREmployeeId = json["chR_EMPLOYEE_ID"];
    }
    if(json["chR_EMPLOYEE_NAME"] is String) {
      chREmployeeName = json["chR_EMPLOYEE_NAME"];
    }
    if(json["chR_EMPLOYEE_ADID"] is String) {
      chREmployeeAdid = json["chR_EMPLOYEE_ADID"];
    }
    if(json["chR_EMPLOYEE_MAIL"] is String) {
      chREmployeeMail = json["chR_EMPLOYEE_MAIL"];
    }
    if(json["chR_POSITION"] is String) {
      chRPosition = json["chR_POSITION"];
    }
    if(json["chR_POSITION_GROUP"] is String) {
      chRPositionGroup = json["chR_POSITION_GROUP"];
    }
  }

  static List<ApproverUser> fromList(List<Map<String, dynamic>> list) {
    return list.map(ApproverUser.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["chR_EMPLOYEE_ID"] = chREmployeeId;
    _data["chR_EMPLOYEE_NAME"] = chREmployeeName;
    _data["chR_EMPLOYEE_ADID"] = chREmployeeAdid;
    _data["chR_EMPLOYEE_MAIL"] = chREmployeeMail;
    _data["chR_POSITION"] = chRPosition;
    _data["chR_POSITION_GROUP"] = chRPositionGroup;
    return _data;
  }
}