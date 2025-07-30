class PthcGroup {
  String? section;
  String? mailto;
  String? mailcc;
  dynamic mailbcc;

  PthcGroup({this.section, this.mailto, this.mailcc, this.mailbcc});

  PthcGroup.fromJson(Map<String, dynamic> json) {
    if(json["section"] is String) {
      section = json["section"];
    }
    if(json["mailto"] is String) {
      mailto = json["mailto"];
    }
    if(json["mailcc"] is String) {
      mailcc = json["mailcc"];
    }
    mailbcc = json["mailbcc"];
  }

  static List<PthcGroup> fromList(List<Map<String, dynamic>> list) {
    return list.map(PthcGroup.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["section"] = section;
    _data["mailto"] = mailto;
    _data["mailcc"] = mailcc;
    _data["mailbcc"] = mailbcc;
    return _data;
  }
}