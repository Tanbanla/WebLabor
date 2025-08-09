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
  // Người phê duyệt
  static const String UserApprover =
      "User/get-employee-section-manager-by-section";

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
  static const String GetGroupPTHC =
      "PthcSection/get-list-mail-groupby-section";
  //PUST
  static const String UpdatePTHC = "PthcSection/update/";
  static const String UpdataListPTHC = "PthcSection/update-multi";
  //DELETE
  static const String DeletePTHCID = "PthcSection/delete/";
  static const String DeletePTHCIDLogic = "PthcSection/delete-logic/";
  static const String DeletePTHCMultiID = "PthcSection/delete-multi/";
  static const String DeletePTHCMultiIDLogic =
      "PthcSection/delete-logic-multi/";
  static const String DeleteByADIDPthc =
      "PthcSection/delete-logic-by-adid-or-email?input=";

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
  static const String DeleteTwoMultiIDLogic =
      "ContractTwoYear/delete-logic-multi/";

  // Contract Apprentice Api
  static const String ApprenticeGetAll = "ContractApprentice/get-all";
  static const String GetApprenticeCount = "ContractApprentice/get-count-all";
  static const String GetByIdApprentice = "ContractApprentice/get/";
  static const String ApprenticeGetByCount =
      "ContractApprentice/get-count-by-condition";
  static const String ApprenticeSreachBy =
      "ContractApprentice/search-by-condition";
  // POST
  static const String AddApprentice = "ContractApprentice/add";
  static const String AddListApprentice = "ContractApprentice/add-multi";
  //PUST
  static const String UpdateApprentice = "ContractApprentice/update/";
  static const String UpdataListApprentice = "ContractApprentice/update-multi";
  //DELETE
  static const String DeleteApprenticeID = "ContractApprentice/delete/";
  static const String DeleteApprenticeIDLogic =
      "ContractApprentice/delete-logic/";
  static const String DeleteApprenticeMultiID =
      "ContractApprentice/delete-multi/";
  static const String DeleteApprenticeMultiIDLogic =
      "ContractApprentice/delete-logic-multi/";

  // Api Chart Home
  static const String ContractTotalByYear = "Report/get-quantity-total-contract-statistic-by-year/";
  static const String ContractTotalByMonth = "Report/get-quantity-total-contract-statistic/";


  // Send mail
  static const String SendMail = "http://172.26.248.62:8501/send-email-notify";
  static const String SendMailCustom =
      "http://172.26.248.62:8501/send-email-notify-custom";

  // font size
  static double sizeColumn = 12;

  // <div style='font-weight: bold;'>
  // THÔNG BÁO YÊU CẦU ĐÁNH GIÁ BỊ TỪ CHỐI<br/>
  // </div>
  static String getRejectionEmailBody({
    required String confirmLink,
    required List<dynamic> rejectedRequests,
  }) {
    // Tạo hàng cho bảng từ danh sách các yêu cầu bị từ chối
    String buildTableRows() {
      // return rejectedRequests
      //     .map(
      //       (request) =>
      //           "<tr><td>${request.vchRCodeApprover ?? 'N/A'}</td><td>${request.vchRCodeApprover ?? 'N/A'}</td><td>${request.vchREmployeeId ?? 'N/A'}</td><td>${request.nvchRApproverPer ?? 'Không có lý do'}</td></tr>",
      //     )
      //     .join();
      return rejectedRequests.map((request) {
        // Xác định lý do từ chối dựa trên statusId
        String rejectionReason;
        switch (request.inTStatusId) {
          case 2:
            rejectionReason = request.nvchRApproverPer ?? 'Không có lý do';
            break;
          case 4:
            if (!request.biTApproverChief) {
              rejectionReason = request.nvchRApproverChief ?? '';
            } else if (!request.biTApproverSectionManager) {
              rejectionReason = request.nvchRApproverManager ?? '';
            } else if (!request.biTApproverDirector) {
              rejectionReason = request.nvchRApproverDirector ?? '';
            } else {
              rejectionReason = 'Không có lý do';
            }
            break;
          default:
            rejectionReason = 'Không có lý do';
        }

        return "<tr>"
            "<td>${request.vchRCodeApprover ?? 'N/A'}</td>"
            "<td>${request.vchRCodeApprover ?? 'N/A'}</td>"
            "<td>${request.vchREmployeeId ?? 'N/A'}</td>"
            "<td>$rejectionReason</td>"
            "</tr>";
      }).join();
    }

    return """---------------------------<br/>Kính gửi: Quản lý phòng ban<br/><br/>Hệ thống thông báo có <span style='color: red; font-weight: bold;'>${rejectedRequests.length} yêu cầu đánh giá BỊ TỪ CHỐI</span>.<br/><br/><table border='1' cellpadding='5' cellspacing='0' style='width: 100%;'><thead><tr style='background-color: #f2f2f2;'><th>Loại đánh giá</th><th>Mã đợt Phát hành</th><th>Mã Nhân viên</th><th>Lý do từ chối</th></tr></thead><tbody>${buildTableRows()}</tbody></table><br/>Bạn vui lòng click vào đường link dưới đây để xác nhận lại:<br/><a href='$confirmLink'>Link xác nhận</a><br/><br/>※Email này được gửi tự động bởi hệ thống LCES, xin vui lòng không reply.<br/>Vui lòng liên lạc cho đảm nhiệm để xác nhận hiện trạng.<br/>--------------------------------------<br/><br/>Hello,<br/><br/>The system informs you that <span style='color: red; font-weight: bold;'>${rejectedRequests.length} evaluation requests have been REJECTED</span>.<br/><br/><table border='1' cellpadding='5' cellspacing='0' style='width: 100%;'><thead><tr style='background-color: #f2f2f2;'><th>Evaluation Type</th><th>Release Code</th><th>Employee Code</th><th>Rejection Reason</th></tr></thead><tbody>${buildTableRows()}</tbody></table><br/>Please click the link below to reconfirm:<br/><a href='$confirmLink'>Confirmation Link</a><br/><br/>※This is an automated email from the LCES system. Please do not reply to this email.<br/>Please contact the responsible person to confirm the current status.""";
  }
}
