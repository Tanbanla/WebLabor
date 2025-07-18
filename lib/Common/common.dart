import 'package:flutter/material.dart';

class Common {
  //color
  static var primaryColor = const Color(0xff296e48);
  static var blackColor = Colors.black54;
  static var greenColor = const Color.fromARGB(255, 156, 179, 131);
  static var grayColor = Colors.grey;
  //API
  static const String API = "http://172.26.248.62:8501/api/";
  //Login
  static const String loginEndpoint = "Account/validate-credentials";

  //Master User
  //GET
  static const String UserGetAll = "User/get-all";
  static const String GetUserCount = "User/get-count-all";
  static const String GetByIdUser = "User/get/";
  static const String UserGetByCount = "User/get-count-by-condition";
  static const String UserSreachBy = "User/search-by-condition";
  // POST
  static const String AddUser = "User/add";
  static const String AddListUser = "User/add-multi";
  //PUST
  static const String UpdateUser = "User/update/";
  static const String UpdataListUser = "User/update-multi";
  //DELETE
  static const String DeleteID = "User/delete/";
  static const String DeleteIDLogic = "User/delete-logic/";
  static const String DeleteMultiID = "User/delete-multi/";
  static const String DeleteMultiIDLogic = "User/delete-logic-multi/";

  // font size
  static double sizeColumn = 12;
}
