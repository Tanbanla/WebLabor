class Pthc {
  int? id;
  String? vchRCodeSection;
  String? vchRNameSection;
  String? vchREmployeeId;
  dynamic nvchREmployeeName;
  String? vchREmployeeAdid;
  String? vchRMail;
  String? vchRUserCreate;
  dynamic dtMCreate;
  String? vchRUserUpdate;
  dynamic dtMUpdate;
  int? inTStatusId;
  dynamic vchRNote;

  Pthc({this.id, this.vchRCodeSection, this.vchRNameSection, this.vchREmployeeId, this.nvchREmployeeName, this.vchREmployeeAdid, this.vchRMail, this.vchRUserCreate, this.dtMCreate, this.vchRUserUpdate, this.dtMUpdate, this.inTStatusId, this.vchRNote});

  Pthc.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    vchRCodeSection = json["vchR_CODE_SECTION"];
    vchRNameSection = json["vchR_NAME_SECTION"];
    vchREmployeeId = json["vchR_EMPLOYEE_ID"];
    nvchREmployeeName = json["nvchR_EMPLOYEE_NAME"];
    vchREmployeeAdid = json["vchR_EMPLOYEE_ADID"];
    vchRMail = json["vchR_MAIL"];
    vchRUserCreate = json["vchR_USER_CREATE"];
    dtMCreate = json["dtM_CREATE"];
    vchRUserUpdate = json["vchR_USER_UPDATE"];
    dtMUpdate = json["dtM_UPDATE"];
    inTStatusId = json["inT_STATUS_ID"];
    vchRNote = json["vchR_NOTE"];
  }

  static List<Pthc> fromList(List<Map<String, dynamic>> list) {
    return list.map(Pthc.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["vchR_CODE_SECTION"] = vchRCodeSection;
    _data["vchR_NAME_SECTION"] = vchRNameSection;
    _data["vchR_EMPLOYEE_ID"] = vchREmployeeId;
    _data["nvchR_EMPLOYEE_NAME"] = nvchREmployeeName;
    _data["vchR_EMPLOYEE_ADID"] = vchREmployeeAdid;
    _data["vchR_MAIL"] = vchRMail;
    _data["vchR_USER_CREATE"] = vchRUserCreate;
    _data["dtM_CREATE"] = dtMCreate;
    _data["vchR_USER_UPDATE"] = vchRUserUpdate;
    _data["dtM_UPDATE"] = dtMUpdate;
    _data["inT_STATUS_ID"] = inTStatusId;
    _data["vchR_NOTE"] = vchRNote;
    return _data;
  }
}