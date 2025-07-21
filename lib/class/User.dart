class User {
  int? id;
  String? chRUserid;
  String? chRPass;
  String? nvchRNameId;
  String? chREmployeeId;
  String? chRGroup;
  int? inTUseridCommon;
  String? chRSecCode;
  String? dtMLastLogin;
  int? inTLock;
  int? inTLockDay;
  dynamic vchRUserCreate;
  String? dtMCreate;
  dynamic vchRUserUpdate;
  String? dtMUpdate;

  User({this.id, this.chRUserid, this.chRPass, this.nvchRNameId, this.chREmployeeId, this.chRGroup, this.inTUseridCommon, this.chRSecCode, this.dtMLastLogin, this.inTLock, this.inTLockDay, this.vchRUserCreate, this.dtMCreate, this.vchRUserUpdate, this.dtMUpdate});

  User.fromJson(Map<String, dynamic> json) {
    if(json["id"] is int) {
      id = json["id"];
    }
    if(json["chR_USERID"] is String) {
      chRUserid = json["chR_USERID"];
    }
    if(json["chR_PASS"] is String) {
      chRPass = json["chR_PASS"];
    }
    if(json["nvchR_NAME_ID"] is String) {
      nvchRNameId = json["nvchR_NAME_ID"];
    }
    if(json["chR_EMPLOYEE_ID"] is String) {
      chREmployeeId = json["chR_EMPLOYEE_ID"];
    }
    if(json["chR_GROUP"] is String) {
      chRGroup = json["chR_GROUP"];
    }
    if(json["inT_USERID_COMMON"] is int) {
      inTUseridCommon = json["inT_USERID_COMMON"];
    }
    if(json["chR_SEC_CODE"] is String) {
      chRSecCode = json["chR_SEC_CODE"];
    }
    if(json["dtM_LAST_LOGIN"] is String) {
      dtMLastLogin = json["dtM_LAST_LOGIN"];
    }
    if(json["inT_LOCK"] is int) {
      inTLock = json["inT_LOCK"];
    }
    if(json["inT_LOCK_DAY"] is int) {
      inTLockDay = json["inT_LOCK_DAY"];
    }
    vchRUserCreate = json["vchR_USER_CREATE"];
    if(json["dtM_CREATE"] is String) {
      dtMCreate = json["dtM_CREATE"];
    }
    vchRUserUpdate = json["vchR_USER_UPDATE"];
    if(json["dtM_UPDATE"] is String) {
      dtMUpdate = json["dtM_UPDATE"];
    }
  }

  static List<User> fromList(List<Map<String, dynamic>> list) {
    return list.map(User.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["chR_USERID"] = chRUserid;
    _data["chR_PASS"] = chRPass;
    _data["nvchR_NAME_ID"] = nvchRNameId;
    _data["chR_EMPLOYEE_ID"] = chREmployeeId;
    _data["chR_GROUP"] = chRGroup;
    _data["inT_USERID_COMMON"] = inTUseridCommon;
    _data["chR_SEC_CODE"] = chRSecCode;
    _data["dtM_LAST_LOGIN"] = dtMLastLogin;
    _data["inT_LOCK"] = inTLock;
    _data["inT_LOCK_DAY"] = inTLockDay;
    _data["vchR_USER_CREATE"] = vchRUserCreate;
    _data["dtM_CREATE"] = dtMCreate;
    _data["vchR_USER_UPDATE"] = vchRUserUpdate;
    _data["dtM_UPDATE"] = dtMUpdate;
    return _data;
  }
}