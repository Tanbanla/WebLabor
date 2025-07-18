class User {
  final int id;
  final String chR_USERID;
  final String chR_PASS;
  final String nvchR_NAME_ID;
  final String chR_EMPLOYEE_ID;
  final String chR_GROUP;
  final int inT_USERID_COMMON;
  final String chR_SEC_CODE;
  final DateTime dtM_LAST_LOGIN;
  final int inT_LOCK;
  final int inT_LOCK_DAY;
  final String? vchR_USER_CREATE;
  final DateTime dtM_CREATE;
  final String? vchR_USER_UPDATE;
  final DateTime dtM_UPDATE;

  User({
    required this.id,
    required this.chR_USERID,
    required this.chR_PASS,
    required this.nvchR_NAME_ID,
    required this.chR_EMPLOYEE_ID,
    required this.chR_GROUP,
    required this.inT_USERID_COMMON,
    required this.chR_SEC_CODE,
    required this.dtM_LAST_LOGIN,
    required this.inT_LOCK,
    required this.inT_LOCK_DAY,
    this.vchR_USER_CREATE,
    required this.dtM_CREATE,
    this.vchR_USER_UPDATE,
    required this.dtM_UPDATE,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      chR_USERID: json['chR_USERID'],
      chR_PASS: json['chR_PASS'],
      nvchR_NAME_ID: json['nvchR_NAME_ID'],
      chR_EMPLOYEE_ID: json['chR_EMPLOYEE_ID'],
      chR_GROUP: json['chR_GROUP'],
      inT_USERID_COMMON: json['inT_USERID_COMMON'],
      chR_SEC_CODE: json['chR_SEC_CODE'],
      dtM_LAST_LOGIN: DateTime.parse(json['dtM_LAST_LOGIN']),
      inT_LOCK: json['inT_LOCK'],
      inT_LOCK_DAY: json['inT_LOCK_DAY'],
      vchR_USER_CREATE: json['vchR_USER_CREATE'],
      dtM_CREATE: DateTime.parse(json['dtM_CREATE']),
      vchR_USER_UPDATE: json['vchR_USER_UPDATE'],
      dtM_UPDATE: DateTime.parse(json['dtM_UPDATE']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chR_USERID': chR_USERID,
      'chR_PASS': chR_PASS,
      'nvchR_NAME_ID': nvchR_NAME_ID,
      'chR_EMPLOYEE_ID': chR_EMPLOYEE_ID,
      'chR_GROUP': chR_GROUP,
      'inT_USERID_COMMON': inT_USERID_COMMON,
      'chR_SEC_CODE': chR_SEC_CODE,
      'dtM_LAST_LOGIN': dtM_LAST_LOGIN.toIso8601String(),
      'inT_LOCK': inT_LOCK,
      'inT_LOCK_DAY': inT_LOCK_DAY,
      'vchR_USER_CREATE': vchR_USER_CREATE,
      'dtM_CREATE': dtM_CREATE.toIso8601String(),
      'vchR_USER_UPDATE': vchR_USER_UPDATE,
      'dtM_UPDATE': dtM_UPDATE.toIso8601String(),
    };
  }
}
