
class Employee {
  bool? success;
  dynamic status;
  dynamic message;
  dynamic error;
  Data? data;

  Employee({this.success, this.status, this.message, this.error, this.data});

  Employee.fromJson(Map<String, dynamic> json) {
    if(json["success"] is bool) {
      success = json["success"];
    }
    status = json["status"];
    message = json["message"];
    error = json["error"];
    if(json["data"] is Map) {
      data = json["data"] == null ? null : Data.fromJson(json["data"]);
    }
  }

  static List<Employee> fromList(List<Map<String, dynamic>> list) {
    return list.map(Employee.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["success"] = success;
    _data["status"] = status;
    _data["message"] = message;
    _data["error"] = error;
    if(data != null) {
      _data["data"] = data?.toJson();
    }
    return _data;
  }
}

class Data {
  int? id;
  String? chRStaffId;
  String? nvchRNameFull;
  dynamic chRCodeDept;
  String? chRCodeSec;
  dynamic chRCodeGroup;
  String? chRCodeCenter;
  int? inTWorkcenter;
  int? iDCluster;
  int? iDStage;
  String? nvchRRemark;
  int? iDWorkLevel;
  dynamic dtMTerminateDate;
  String? dtMJoinDate;
  String? dtMJoinDateOption1;
  String? nvchRNumPhoneStaff;
  String? nvchRStageIncrease;
  String? chRCrtUserid;
  dynamic dtMCreate;
  String? chRUpdUserid;
  String? dtMUpdate;
  int? inTTotalDayoff;
  String? vchRShiftCode;
  String? vchRNote1;
  String? vchRNote2;
  String? vchROther1;
  dynamic vchROther2;
  dynamic vchROther3;
  dynamic dtMJoinSection;
  dynamic dtMMaternity;
  dynamic chRStatusDelete;
  String? vchRSkipCode;

  Data({this.id, this.chRStaffId, this.nvchRNameFull, this.chRCodeDept, this.chRCodeSec, this.chRCodeGroup, this.chRCodeCenter, this.inTWorkcenter, this.iDCluster, this.iDStage, this.nvchRRemark, this.iDWorkLevel, this.dtMTerminateDate, this.dtMJoinDate, this.dtMJoinDateOption1, this.nvchRNumPhoneStaff, this.nvchRStageIncrease, this.chRCrtUserid, this.dtMCreate, this.chRUpdUserid, this.dtMUpdate, this.inTTotalDayoff, this.vchRShiftCode, this.vchRNote1, this.vchRNote2, this.vchROther1, this.vchROther2, this.vchROther3, this.dtMJoinSection, this.dtMMaternity, this.chRStatusDelete, this.vchRSkipCode});

  Data.fromJson(Map<String, dynamic> json) {
    if(json["id"] is int) {
      id = json["id"];
    }
    if(json["chR_STAFF_ID"] is String) {
      chRStaffId = json["chR_STAFF_ID"];
    }
    if(json["nvchR_NAME_FULL"] is String) {
      nvchRNameFull = json["nvchR_NAME_FULL"];
    }
    chRCodeDept = json["chR_CODE_DEPT"];
    if(json["chR_CODE_SEC"] is String) {
      chRCodeSec = json["chR_CODE_SEC"];
    }
    chRCodeGroup = json["chR_CODE_GROUP"];
    if(json["chR_CODE_CENTER"] is String) {
      chRCodeCenter = json["chR_CODE_CENTER"];
    }
    if(json["inT_WORKCENTER"] is int) {
      inTWorkcenter = json["inT_WORKCENTER"];
    }
    if(json["iD_CLUSTER"] is int) {
      iDCluster = json["iD_CLUSTER"];
    }
    if(json["iD_STAGE"] is int) {
      iDStage = json["iD_STAGE"];
    }
    if(json["nvchR_REMARK"] is String) {
      nvchRRemark = json["nvchR_REMARK"];
    }
    if(json["iD_WORK_LEVEL"] is int) {
      iDWorkLevel = json["iD_WORK_LEVEL"];
    }
    dtMTerminateDate = json["dtM_TERMINATE_DATE"];
    if(json["dtM_JOIN_DATE"] is String) {
      dtMJoinDate = json["dtM_JOIN_DATE"];
    }
    if(json["dtM_JOIN_DATE_OPTION1"] is String) {
      dtMJoinDateOption1 = json["dtM_JOIN_DATE_OPTION1"];
    }
    if(json["nvchR_NUM_PHONE_STAFF"] is String) {
      nvchRNumPhoneStaff = json["nvchR_NUM_PHONE_STAFF"];
    }
    if(json["nvchR_STAGE_INCREASE"] is String) {
      nvchRStageIncrease = json["nvchR_STAGE_INCREASE"];
    }
    if(json["chR_CRT_USERID"] is String) {
      chRCrtUserid = json["chR_CRT_USERID"];
    }
    dtMCreate = json["dtM_CREATE"];
    if(json["chR_UPD_USERID"] is String) {
      chRUpdUserid = json["chR_UPD_USERID"];
    }
    if(json["dtM_UPDATE"] is String) {
      dtMUpdate = json["dtM_UPDATE"];
    }
    if(json["inT_TOTAL_DAYOFF"] is int) {
      inTTotalDayoff = json["inT_TOTAL_DAYOFF"];
    }
    if(json["vchR_SHIFT_CODE"] is String) {
      vchRShiftCode = json["vchR_SHIFT_CODE"];
    }
    if(json["vchR_NOTE1"] is String) {
      vchRNote1 = json["vchR_NOTE1"];
    }
    if(json["vchR_NOTE2"] is String) {
      vchRNote2 = json["vchR_NOTE2"];
    }
    if(json["vchR_OTHER1"] is String) {
      vchROther1 = json["vchR_OTHER1"];
    }
    vchROther2 = json["vchR_OTHER2"];
    vchROther3 = json["vchR_OTHER3"];
    dtMJoinSection = json["dtM_JOIN_SECTION"];
    dtMMaternity = json["dtM_MATERNITY"];
    chRStatusDelete = json["chR_STATUS_DELETE"];
    if(json["vchR_SKIP_CODE"] is String) {
      vchRSkipCode = json["vchR_SKIP_CODE"];
    }
  }

  static List<Data> fromList(List<Map<String, dynamic>> list) {
    return list.map(Data.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["chR_STAFF_ID"] = chRStaffId;
    _data["nvchR_NAME_FULL"] = nvchRNameFull;
    _data["chR_CODE_DEPT"] = chRCodeDept;
    _data["chR_CODE_SEC"] = chRCodeSec;
    _data["chR_CODE_GROUP"] = chRCodeGroup;
    _data["chR_CODE_CENTER"] = chRCodeCenter;
    _data["inT_WORKCENTER"] = inTWorkcenter;
    _data["iD_CLUSTER"] = iDCluster;
    _data["iD_STAGE"] = iDStage;
    _data["nvchR_REMARK"] = nvchRRemark;
    _data["iD_WORK_LEVEL"] = iDWorkLevel;
    _data["dtM_TERMINATE_DATE"] = dtMTerminateDate;
    _data["dtM_JOIN_DATE"] = dtMJoinDate;
    _data["dtM_JOIN_DATE_OPTION1"] = dtMJoinDateOption1;
    _data["nvchR_NUM_PHONE_STAFF"] = nvchRNumPhoneStaff;
    _data["nvchR_STAGE_INCREASE"] = nvchRStageIncrease;
    _data["chR_CRT_USERID"] = chRCrtUserid;
    _data["dtM_CREATE"] = dtMCreate;
    _data["chR_UPD_USERID"] = chRUpdUserid;
    _data["dtM_UPDATE"] = dtMUpdate;
    _data["inT_TOTAL_DAYOFF"] = inTTotalDayoff;
    _data["vchR_SHIFT_CODE"] = vchRShiftCode;
    _data["vchR_NOTE1"] = vchRNote1;
    _data["vchR_NOTE2"] = vchRNote2;
    _data["vchR_OTHER1"] = vchROther1;
    _data["vchR_OTHER2"] = vchROther2;
    _data["vchR_OTHER3"] = vchROther3;
    _data["dtM_JOIN_SECTION"] = dtMJoinSection;
    _data["dtM_MATERNITY"] = dtMMaternity;
    _data["chR_STATUS_DELETE"] = chRStatusDelete;
    _data["vchR_SKIP_CODE"] = vchRSkipCode;
    return _data;
  }
}