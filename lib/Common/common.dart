import 'package:flutter/material.dart';

class Common {
  //color
  static var primaryColor = const Color(0xff296e48);
  static var blackColor = Colors.black54;
  static var greenColor = const Color.fromARGB(255, 156, 179, 131);
  static var grayColor = Colors.grey;
  //API
  static const String API = "http://172.26.248.62:8501/api/";
  // font size
  static double sizeColumn = 12;
  // cloumn
  static const List<String> ColumnTwoVn = ["STT","Mã nhân viên","M/F","Họ và tên",
  "Phòng ban","Nhóm","Tuổi","Vị trí","Bậc lương","Hiệu lực HD","Ngày kết thúc hợp đồng","Số lần đi muộn, về sớm","Nghỉ hưởng lương","Nghỉ không lương","Nghỉ không báo cáo"
  ,"Số lần vi phạm nội quy công ty","Lý do","Kết quả khám sức khỏe","Kết quả đánh giá","Trường hợp không tuyển dụng lại điền 'X'","Lý do không tuyển dụng lại"];
}
