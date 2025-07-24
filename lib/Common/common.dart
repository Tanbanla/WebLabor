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


  // Master PTHC
    //GET
  static const String PTHCGetAll = "PthcSection/get-all";
  static const String GetPTHCCount = "PthcSection/get-count-all";
  static const String GetByIdPTHC = "PthcSection/get/";
  static const String PTHCGetByCount = "PthcSection/get-count-by-condition";
  static const String PTHCSreachBy = "PthcSection/search-by-condition";
  // POST
  static const String AddPTHC = "PthcSection/add";
  static const String AddListPTHC = "PthcSection/add-multi";
  //PUST
  static const String UpdatePTHC = "PthcSection/update/";
  static const String UpdataListPTHC = "PthcSection/update-multi";
  //DELETE
  static const String DeletePTHCID = "PthcSection/delete/";
  static const String DeletePTHCIDLogic = "PthcSection/delete-logic/";
  static const String DeletePTHCMultiID = "PthcSection/delete-multi/";
  static const String DeletePTHCMultiIDLogic = "PthcSection/delete-logic-multi/";

  // Contract Two year
    static const String TwoGetAll = "ContractTwoYear/get-all";
  static const String GetTwoCount = "ContractTwoYear/get-count-all";
  static const String GetByIdTwo = "ContractTwoYear/get/";
  static const String TwoGetByCount = "ContractTwoYear/get-count-by-condition";
  static const String TwoSreachBy = "ContractTwoYear/search-by-condition";
  // POST
  static const String AddTwo = "ContractTwoYear/add";
  static const String AddListTwo = "ContractTwoYear/add-multi";
  //PUST
  static const String UpdateTwo = "ContractTwoYear/update/";
  static const String UpdataListTwo = "ContractTwoYear/update-multi";
  //DELETE
  static const String DeleteTwoID = "ContractTwoYear/delete/";
  static const String DeleteTwoIDLogic = "ContractTwoYear/delete-logic/";
  static const String DeleteTwoMultiID = "ContractTwoYear/delete-multi/";
  static const String DeleteTwoMultiIDLogic = "ContractTwoYear/delete-logic-multi/";
  // font size
  static double sizeColumn = 12;
}
