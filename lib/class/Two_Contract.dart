class TwoContract {
  int? id;
  String? vchRCodeApprover;
  String? vchRCodeSection;
  String? vchRNameSection;
  String? vchREmployeeId;
  String? vchRTyperId;
  String? vchREmployeeName;
  String? dtMBrithday;
  String? chRPosition;
  String? chRCodeGrade;
  String? chRCostCenterName;
  String? dtMJoinDate;
  String? dtMEndDate;
  double? fLGoLeaveLate;
  double? fLPaidLeave;
  double? fLNotPaidLeave;
  double? fLNotLeaveDay;
  int? inTViolation;
  String? nvarchaRViolation;
  String? nvchRCompleteWork;
  String? nvchRUseful;
  String? nvchROther;
  String? vchRReasultsLeader;
  dynamic biTNoReEmployment;
  dynamic nvchRNoReEmpoyment;
  dynamic nvchRPthcSection;
  dynamic vchRLeaderEvalution;
  dynamic dtMLeadaerEvalution;
  bool? biTApproverPer;
  String? nvchRApproverPer;
  String? dtMApproverPer;
  dynamic biTApproverChief;
  dynamic nvchRApproverChief;
  dynamic dtMApproverChief;
  dynamic biTApproverSectionManager;
  dynamic nvchRApproverManager;
  dynamic dtMApproverManager;
  dynamic biTApproverDirector;
  dynamic nvchRApproverDirector;
  dynamic dtMApproverDirector;
  String? vchRUserCreate;
  String? dtMCreate;
  String? vchRUserUpdate;
  String? dtMUpdate;
  int? inTStatusId;
  dynamic vchRNote;
  String? useRApproverPer;
  dynamic useRApproverChief;
  dynamic useRApproverSectionManager;
  dynamic useRApproverDirector;
  String? dtMDueDate;
  String? dtmApproverDeft;
  String? userApproverDeft;
  bool? bitApproverDeft;
  String? nvchrApproverDeft;

  TwoContract({
    this.id,
    this.vchRCodeApprover,
    this.vchRCodeSection,
    this.vchRNameSection,
    this.vchREmployeeId,
    this.vchRTyperId,
    this.vchREmployeeName,
    this.dtMBrithday,
    this.chRPosition,
    this.chRCodeGrade,
    this.chRCostCenterName,
    this.dtMJoinDate,
    this.dtMEndDate,
    this.fLGoLeaveLate,
    this.fLPaidLeave,
    this.fLNotPaidLeave,
    this.fLNotLeaveDay,
    this.inTViolation,
    this.nvarchaRViolation,
    this.nvchRCompleteWork,
    this.nvchRUseful,
    this.nvchROther,
    this.vchRReasultsLeader,
    this.biTNoReEmployment,
    this.nvchRNoReEmpoyment,
    this.nvchRPthcSection,
    this.vchRLeaderEvalution,
    this.dtMLeadaerEvalution,
    this.biTApproverPer,
    this.nvchRApproverPer,
    this.dtMApproverPer,
    this.biTApproverChief,
    this.nvchRApproverChief,
    this.dtMApproverChief,
    this.biTApproverSectionManager,
    this.nvchRApproverManager,
    this.dtMApproverManager,
    this.biTApproverDirector,
    this.nvchRApproverDirector,
    this.dtMApproverDirector,
    this.vchRUserCreate,
    this.dtMCreate,
    this.vchRUserUpdate,
    this.dtMUpdate,
    this.inTStatusId,
    this.vchRNote,
    this.useRApproverPer,
    this.useRApproverChief,
    this.useRApproverSectionManager,
    this.useRApproverDirector,
    this.dtMDueDate,
    this.dtmApproverDeft,
    this.userApproverDeft,
    this.bitApproverDeft,
    this.nvchrApproverDeft,
  });

  TwoContract.fromJson(Map<String, dynamic> json) {
    if (json["id"] is int) {
      id = json["id"];
    }
    if (json["vchR_CODE_APPROVER"] is String) {
      vchRCodeApprover = json["vchR_CODE_APPROVER"];
    }
    if (json["vchR_CODE_SECTION"] is String) {
      vchRCodeSection = json["vchR_CODE_SECTION"];
    }
    if (json["vchR_NAME_SECTION"] is String) {
      vchRNameSection = json["vchR_NAME_SECTION"];
    }
    if (json["vchR_EMPLOYEE_ID"] is String) {
      vchREmployeeId = json["vchR_EMPLOYEE_ID"];
    }
    if (json["vchR_TYPER_ID"] is String) {
      vchRTyperId = json["vchR_TYPER_ID"];
    }
    if (json["vchR_EMPLOYEE_NAME"] is String) {
      vchREmployeeName = json["vchR_EMPLOYEE_NAME"];
    }
    if (json["dtM_BRITHDAY"] is String) {
      dtMBrithday = json["dtM_BRITHDAY"];
    }
    if (json["chR_POSITION"] is String) {
      chRPosition = json["chR_POSITION"];
    }
    if (json["chR_CODE_GRADE"] is String) {
      chRCodeGrade = json["chR_CODE_GRADE"];
    }
    if (json["chR_COST_CENTER_NAME"] is String) {
      chRCostCenterName = json["chR_COST_CENTER_NAME"];
    }
    if (json["dtM_JOIN_DATE"] is String) {
      dtMJoinDate = json["dtM_JOIN_DATE"];
    }
    if (json["dtM_END_DATE"] is String) {
      dtMEndDate = json["dtM_END_DATE"];
    }
    if (json["fL_GO_LEAVE_LATE"] is int) {
      fLGoLeaveLate = json["fL_GO_LEAVE_LATE"];
    }
    if (json["fL_PAID_LEAVE"] is double) {
      fLPaidLeave = json["fL_PAID_LEAVE"];
    }
    if (json["fL_NOT_PAID_LEAVE"] is double) {
      fLNotPaidLeave = json["fL_NOT_PAID_LEAVE"];
    }
    if (json["fL_NOT_LEAVE_DAY"] is int) {
      fLNotLeaveDay = json["fL_NOT_LEAVE_DAY"];
    }
    if (json["inT_VIOLATION"] is int) {
      inTViolation = json["inT_VIOLATION"];
    }
    if (json["nvarchaR_VIOLATION"] is String) {
      nvarchaRViolation = json["nvarchaR_VIOLATION"];
    }
    nvchRCompleteWork = json["nvchR_COMPLETE_WORK"];
    nvchRUseful = json["nvchR_USEFUL"];
    nvchROther = json["nvchR_OTHER"];
    vchRReasultsLeader = json["vchR_REASULTS_LEADER"];
    biTNoReEmployment = json["biT_NO_RE_EMPLOYMENT"];
    nvchRNoReEmpoyment = json["nvchR_NO_RE_EMPOYMENT"];
    nvchRPthcSection = json["nvchR_PTHC_SECTION"];
    vchRLeaderEvalution = json["vchR_LEADER_EVALUTION"];
    dtMLeadaerEvalution = json["dtM_LEADAER_EVALUTION"];
    if (json["biT_APPROVER_PER"] is bool) {
      biTApproverPer = json["biT_APPROVER_PER"];
    }
    if (json["nvchR_APPROVER_PER"] is String) {
      nvchRApproverPer = json["nvchR_APPROVER_PER"];
    }
    if (json["dtM_APPROVER_PER"] is String) {
      dtMApproverPer = json["dtM_APPROVER_PER"];
    }
    biTApproverChief = json["biT_APPROVER_CHIEF"];
    nvchRApproverChief = json["nvchR_APPROVER_CHIEF"];
    dtMApproverChief = json["dtM_APPROVER_CHIEF"];
    biTApproverSectionManager = json["biT_APPROVER_SECTION_MANAGER"];
    nvchRApproverManager = json["nvchR_APPROVER_MANAGER"];
    dtMApproverManager = json["dtM_APPROVER_MANAGER"];
    biTApproverDirector = json["biT_APPROVER_DIRECTOR"];
    nvchRApproverDirector = json["nvchR_APPROVER_DIRECTOR"];
    dtMApproverDirector = json["dtM_APPROVER_DIRECTOR"];
    if (json["vchR_USER_CREATE"] is String) {
      vchRUserCreate = json["vchR_USER_CREATE"];
    }
    if (json["dtM_CREATE"] is String) {
      dtMCreate = json["dtM_CREATE"];
    }
    if (json["vchR_USER_UPDATE"] is String) {
      vchRUserUpdate = json["vchR_USER_UPDATE"];
    }
    if (json["dtM_UPDATE"] is String) {
      dtMUpdate = json["dtM_UPDATE"];
    }
    if (json["inT_STATUS_ID"] is int) {
      inTStatusId = json["inT_STATUS_ID"];
    }
    vchRNote = json["vchR_NOTE"];
    if (json["useR_APPROVER_PER"] is String) {
      useRApproverPer = json["useR_APPROVER_PER"];
    }
    useRApproverChief = json["useR_APPROVER_CHIEF"];
    useRApproverSectionManager = json["useR_APPROVER_SECTION_MANAGER"];
    useRApproverDirector = json["useR_APPROVER_DIRECTOR"];
    if (json["dtM_DUE_DATE"] is String) {
      dtMDueDate = json["dtM_DUE_DATE"];
    }
    if (json["DTM_APPROVER_DEFT"] is String) {
      dtmApproverDeft = json["DTM_APPROVER_DEFT"];
    }
    if (json["USER_APPROVER_DEFT"] is String) {
      userApproverDeft = json["USER_APPROVER_DEFT"];
    }
    if (json["BIT_APRROVER_DEFT"] is bool) {
      bitApproverDeft = json["BIT_APRROVER_DEFT"];
    }
    if (json["NVCHR_APROVER_DEFT"] is String) {
      nvchrApproverDeft = json["NVCHR_APROVER_DEFT"];
    }
  }

  static List<TwoContract> fromList(List<Map<String, dynamic>> list) {
    return list.map(TwoContract.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["vchR_CODE_APPROVER"] = vchRCodeApprover;
    _data["vchR_CODE_SECTION"] = vchRCodeSection;
    _data["vchR_NAME_SECTION"] = vchRNameSection;
    _data["vchR_EMPLOYEE_ID"] = vchREmployeeId;
    _data["vchR_TYPER_ID"] = vchRTyperId;
    _data["vchR_EMPLOYEE_NAME"] = vchREmployeeName;
    _data["dtM_BRITHDAY"] = dtMBrithday;
    _data["chR_POSITION"] = chRPosition;
    _data["chR_CODE_GRADE"] = chRCodeGrade;
    _data["chR_COST_CENTER_NAME"] = chRCostCenterName;
    _data["dtM_JOIN_DATE"] = dtMJoinDate;
    _data["dtM_END_DATE"] = dtMEndDate;
    _data["fL_GO_LEAVE_LATE"] = fLGoLeaveLate;
    _data["fL_PAID_LEAVE"] = fLPaidLeave;
    _data["fL_NOT_PAID_LEAVE"] = fLNotPaidLeave;
    _data["fL_NOT_LEAVE_DAY"] = fLNotLeaveDay;
    _data["inT_VIOLATION"] = inTViolation;
    _data["nvarchaR_VIOLATION"] = nvarchaRViolation;
    _data["nvchR_COMPLETE_WORK"] = nvchRCompleteWork;
    _data["nvchR_USEFUL"] = nvchRUseful;
    _data["nvchR_OTHER"] = nvchROther;
    _data["vchR_REASULTS_LEADER"] = vchRReasultsLeader;
    _data["biT_NO_RE_EMPLOYMENT"] = biTNoReEmployment;
    _data["nvchR_NO_RE_EMPOYMENT"] = nvchRNoReEmpoyment;
    _data["nvchR_PTHC_SECTION"] = nvchRPthcSection;
    _data["vchR_LEADER_EVALUTION"] = vchRLeaderEvalution;
    _data["dtM_LEADAER_EVALUTION"] = dtMLeadaerEvalution;
    _data["biT_APPROVER_PER"] = biTApproverPer;
    _data["nvchR_APPROVER_PER"] = nvchRApproverPer;
    _data["dtM_APPROVER_PER"] = dtMApproverPer;
    _data["biT_APPROVER_CHIEF"] = biTApproverChief;
    _data["nvchR_APPROVER_CHIEF"] = nvchRApproverChief;
    _data["dtM_APPROVER_CHIEF"] = dtMApproverChief;
    _data["biT_APPROVER_SECTION_MANAGER"] = biTApproverSectionManager;
    _data["nvchR_APPROVER_MANAGER"] = nvchRApproverManager;
    _data["dtM_APPROVER_MANAGER"] = dtMApproverManager;
    _data["biT_APPROVER_DIRECTOR"] = biTApproverDirector;
    _data["nvchR_APPROVER_DIRECTOR"] = nvchRApproverDirector;
    _data["dtM_APPROVER_DIRECTOR"] = dtMApproverDirector;
    _data["vchR_USER_CREATE"] = vchRUserCreate;
    _data["dtM_CREATE"] = dtMCreate;
    _data["vchR_USER_UPDATE"] = vchRUserUpdate;
    _data["dtM_UPDATE"] = dtMUpdate;
    _data["inT_STATUS_ID"] = inTStatusId;
    _data["vchR_NOTE"] = vchRNote;
    _data["useR_APPROVER_PER"] = useRApproverPer;
    _data["useR_APPROVER_CHIEF"] = useRApproverChief;
    _data["useR_APPROVER_SECTION_MANAGER"] = useRApproverSectionManager;
    _data["useR_APPROVER_DIRECTOR"] = useRApproverDirector;
    _data["dtM_DUE_DATE"] = dtMDueDate;
    _data["DTM_APPROVER_DEFT"] = dtmApproverDeft;
    _data["USER_APPROVER_DEFT"] = userApproverDeft;
    _data["BIT_APRROVER_DEFT"] = bitApproverDeft;
    _data["NVCHR_APROVER_DEFT"] = nvchrApproverDeft;
    return _data;
  }
}
// Director
// Expert
// Technician
// General Director
// Chief
// Dept Manager
// Leader
// Supervisor
// Section Manager
// Staff
// Operator


// {
//   "pageNumber": -1,
//   "pageSize": 10,
//   "filters": [
//     {
//       "field": "CHR_GROUP",
//       "value": "Expert",
//       "operator": "=",
//       "logicType": "AND"
//     }
//   ]
// }