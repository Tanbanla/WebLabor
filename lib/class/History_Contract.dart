class HistoryContract {
  int? id;
  String? vchRCodeApprover;
  String? vchRLeaderEvalution;
  String? dtMLeadaerEvalution;
  bool? biTApproverPer;
  String? nvchRApproverPer;
  String? dtMApproverPer;
  String? nvchRPthcSection;
  String? dtMPthcSection;
  bool? biTApproverChief;
  String? nvchRApproverChief;
  String? dtMApproverChief;
  bool? biTApproverSectionManager;
  String? nvchRApproverManager;
  String? dtMApproverManager;
  bool? biTApproverDirector;
  String? nvchRApproverDirector;
  String? dtMApproverDirector;
  String? vchRUserCreate;
  String? dtMCreate;
  String? vchRUserUpdate;
  String? dtMUpdate;
  int? inTStatusId;
  String? vchRNote;
  String? useRApproverPer;
  String? useRApproverChief;
  String? useRApproverSectionManager;
  String? useRApproverDirector;

  HistoryContract({this.id, this.vchRCodeApprover, this.vchRLeaderEvalution, this.dtMLeadaerEvalution, this.biTApproverPer, this.nvchRApproverPer, this.dtMApproverPer, this.nvchRPthcSection, this.dtMPthcSection, this.biTApproverChief, this.nvchRApproverChief, this.dtMApproverChief, this.biTApproverSectionManager, this.nvchRApproverManager, this.dtMApproverManager, this.biTApproverDirector, this.nvchRApproverDirector, this.dtMApproverDirector, this.vchRUserCreate, this.dtMCreate, this.vchRUserUpdate, this.dtMUpdate, this.inTStatusId, this.vchRNote, this.useRApproverPer, this.useRApproverChief, this.useRApproverSectionManager, this.useRApproverDirector});

  HistoryContract.fromJson(Map<String, dynamic> json) {
    if(json["id"] is int) {
      id = json["id"];
    }
    if(json["vchR_CODE_APPROVER"] is String) {
      vchRCodeApprover = json["vchR_CODE_APPROVER"];
    }
    if(json["vchR_LEADER_EVALUTION"] is String) {
      vchRLeaderEvalution = json["vchR_LEADER_EVALUTION"];
    }
    if(json["dtM_LEADAER_EVALUTION"] is String) {
      dtMLeadaerEvalution = json["dtM_LEADAER_EVALUTION"];
    }
    if(json["biT_APPROVER_PER"] is bool) {
      biTApproverPer = json["biT_APPROVER_PER"];
    }
    if(json["nvchR_APPROVER_PER"] is String) {
      nvchRApproverPer = json["nvchR_APPROVER_PER"];
    }
    if(json["dtM_APPROVER_PER"] is String) {
      dtMApproverPer = json["dtM_APPROVER_PER"];
    }
    if(json["nvchR_PTHC_SECTION"] is String) {
      nvchRPthcSection = json["nvchR_PTHC_SECTION"];
    }
    if(json["dtM_PTHC_SECTION"] is String) {
      dtMPthcSection = json["dtM_PTHC_SECTION"];
    }
    if(json["biT_APPROVER_CHIEF"] is bool) {
      biTApproverChief = json["biT_APPROVER_CHIEF"];
    }
    if(json["nvchR_APPROVER_CHIEF"] is String) {
      nvchRApproverChief = json["nvchR_APPROVER_CHIEF"];
    }
    if(json["dtM_APPROVER_CHIEF"] is String) {
      dtMApproverChief = json["dtM_APPROVER_CHIEF"];
    }
    if(json["biT_APPROVER_SECTION_MANAGER"] is bool) {
      biTApproverSectionManager = json["biT_APPROVER_SECTION_MANAGER"];
    }
    if(json["nvchR_APPROVER_MANAGER"] is String) {
      nvchRApproverManager = json["nvchR_APPROVER_MANAGER"];
    }
    if(json["dtM_APPROVER_MANAGER"] is String) {
      dtMApproverManager = json["dtM_APPROVER_MANAGER"];
    }
    if(json["biT_APPROVER_DIRECTOR"] is bool) {
      biTApproverDirector = json["biT_APPROVER_DIRECTOR"];
    }
    if(json["nvchR_APPROVER_DIRECTOR"] is String) {
      nvchRApproverDirector = json["nvchR_APPROVER_DIRECTOR"];
    }
    if(json["dtM_APPROVER_DIRECTOR"] is String) {
      dtMApproverDirector = json["dtM_APPROVER_DIRECTOR"];
    }
    if(json["vchR_USER_CREATE"] is String) {
      vchRUserCreate = json["vchR_USER_CREATE"];
    }
    if(json["dtM_CREATE"] is String) {
      dtMCreate = json["dtM_CREATE"];
    }
    if(json["vchR_USER_UPDATE"] is String) {
      vchRUserUpdate = json["vchR_USER_UPDATE"];
    }
    if(json["dtM_UPDATE"] is String) {
      dtMUpdate = json["dtM_UPDATE"];
    }
    if(json["inT_STATUS_ID"] is int) {
      inTStatusId = json["inT_STATUS_ID"];
    }
    if(json["vchR_NOTE"] is String) {
      vchRNote = json["vchR_NOTE"];
    }
    if(json["useR_APPROVER_PER"] is String) {
      useRApproverPer = json["useR_APPROVER_PER"];
    }
    if(json["useR_APPROVER_CHIEF"] is String) {
      useRApproverChief = json["useR_APPROVER_CHIEF"];
    }
    if(json["useR_APPROVER_SECTION_MANAGER"] is String) {
      useRApproverSectionManager = json["useR_APPROVER_SECTION_MANAGER"];
    }
    if(json["useR_APPROVER_DIRECTOR"] is String) {
      useRApproverDirector = json["useR_APPROVER_DIRECTOR"];
    }
  }

  static List<HistoryContract> fromList(List<Map<String, dynamic>> list) {
    return list.map(HistoryContract.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["vchR_CODE_APPROVER"] = vchRCodeApprover;
    _data["vchR_LEADER_EVALUTION"] = vchRLeaderEvalution;
    _data["dtM_LEADAER_EVALUTION"] = dtMLeadaerEvalution;
    _data["biT_APPROVER_PER"] = biTApproverPer;
    _data["nvchR_APPROVER_PER"] = nvchRApproverPer;
    _data["dtM_APPROVER_PER"] = dtMApproverPer;
    _data["nvchR_PTHC_SECTION"] = nvchRPthcSection;
    _data["dtM_PTHC_SECTION"] = dtMPthcSection;
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
    return _data;
  }
}