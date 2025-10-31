import 'package:flutter/material.dart';

class Common {
  //color
  static var primaryColor = const Color(0xff296e48);
  static var blackColor = Colors.black54;
  static var greenColor = const Color.fromARGB(255, 156, 179, 131);
  static var grayColor = Colors.grey;
  // API base (dynamic between http / https when running on web).
  // If the app is served via https we must call the https backend (port 44351).
  // If the app is served via http we call the http backend (port 8501).
  // For non-web platforms we default to the http base unless overridden.
  static const String _httpBase = "http://172.26.248.62:8501/api/";
  static const String _httpsBase =
      "https://172.26.248.62:44351/api/"; // already ends with /

  // Use a getter instead of const so callers always get the right value at runtime.
  static String get API {
    // kIsWeb requires importing foundation; to avoid adding import in all files we inline detection using identical(0, 0.0)
    // Better: use kIsWeb from flutter/foundation.
    // We'll import foundation at top.
    assert(
      _httpBase.endsWith('/') && _httpsBase.endsWith('/'),
      'Base URLs should end with /',
    );
    if (identical(0, 0.0)) {
      // This branch is never executed, placeholder to silence analyzer if foundation not imported.
    }
    // Try web detection via Uri.base.scheme (works on all platforms, returns e.g. 'http','https','file')
    final scheme =
        Uri.base.scheme; // On web will be http/https, on mobile usually 'file'
    if (scheme == 'https') {
      return _httpsBase;
    }
    if (scheme == 'http') {
      return _httpBase;
    }
    // Fallback for non-web (mobile/desktop) -> choose http base (can adjust if needed)
    return _httpBase;
  }

  //Login
  static const String loginEndpoint = "Account/validate-credentials";
  static const String AccountLogin = "Account/login";

  //Master User
  //GET
  static const String UserGetAll = "User/get-all";
  static const String GetUserCount = "User/get-count-all";
  static const String GetByIdUser = "User/get/";
  static const String UserGetByCount = "User/get-count-by-condition";
  static const String UserSreachBy = "User/search-by-condition";
  // Lấy thongo thông tin nhân viên theo mã nhân viên từ Agent
  static const String GetEmployeeByStaffID =
      "User/get-employee-by-staffid?staffId=";
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
  // Lấy thông tin danh sách phòng ban
  static const String UserSection = "User/get-all-section";
  // Master PTHC
  //GET
  static const String PTHCGetAll = "PthcSection/get-all";
  static const String GetPTHCCount = "PthcSection/get-count-all";
  static const String GetByIdPTHC = "PthcSection/get/";
  static const String PTHCGetByCount = "PthcSection/get-count-by-condition";
  static const String PTHCSreachBy = "PthcSection/search-by-condition";
  // lấy thông tin phòng
  static const String GetSection =
      "PthcSection/get-list-picsection-by-employeeadid?adid=";
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
  static const String DeleteTwoMultiID = "ContractTwoYear/delete-multi";
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
      "ContractApprentice/delete-multi";
  static const String DeleteApprenticeMultiIDLogic =
      "ContractApprentice/delete-logic-multi/";

  // Api Chart Home
  static const String ContractTotalByYear =
      "Report/get-quantity-total-contract-statistic-by-year/";
  static const String ContractTotalByMonth =
      "Report/get-quantity-total-contract-statistic/";

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
    required String loaiTuChoi,
    required String approverNG,
    required List<dynamic> rejectedRequests,
    required String? reson,
  }) {
    // Tạo hàng cho bảng từ danh sách các yêu cầu bị từ chối
    String buildTableRows() {
      return rejectedRequests.map((request) {
        // Xác định lý do từ chối dựa trên statusId
        String rejectionReason;
        switch (request.inTStatusId) {
          case 2:
            rejectionReason = request.nvchRApproverPer ?? 'Không có lý do';
            break;
          case 3:
            rejectionReason = reson ?? 'Không có lý do';
            break;
          case 4:
            rejectionReason = reson ?? 'Không có lý do';
            break;
          case 5:
            rejectionReason = request.nvchRApproverChief ?? 'Không có lý do';
            break;
          case 6:
            rejectionReason = request.nvchRApproverManager ?? 'Không có lý do';
            break;
          case 7:
            rejectionReason = request.nvchrApproverDeft ?? 'Không có lý do';
            break;
          case 8:
            rejectionReason = request.nvchRApproverDirector ?? 'Không có lý do';
            break;
          default:
            rejectionReason = 'Không có lý do';
        }

        return "<tr>"
            "<td>${request.vchRCodeApprover ?? 'N/A'}</td>"
            "<td>${request.vchRCodeApprover ?? 'N/A'}</td>"
            "<td>${request.vchREmployeeId ?? 'N/A'}</td>"
            "<td>$rejectionReason</td>"
            "<td>$approverNG</td>"
            "<td>$loaiTuChoi</td>"
            "</tr>";
      }).join();
    }

    return """---------------------------<br/>こんにちは、<br/><br/>これはブラザーベトナム工業株式会社（LCES）の労働契約評価システムから送信されたメールです。<br/><span style='color: red; font-weight: bold;'>${rejectedRequests.length} 件の評価が拒否されたことがシステムから通知されます。</span><br/><br/><table border='1' cellpadding='5' cellspacing='0' style='width: 100%;'><thead><tr style='background-color: #f2f2f2;'><th>評価タイプ</th><th>リリースバッチコード</th><th>従業員規約</th><th>拒否理由</th><th>拒否者</th><th>拒否タイプ</th></tr></thead><tbody>${buildTableRows()}</tbody></table><br/>再確認するには以下のリンクをクリックしてください:<br/><a href='$confirmLink'>Confirmation Link</a><br/><br/>※このメールはLCESシステムから自動送信されたので、返信しないでください。<br/>現在の状況を確認するには担当者にお問い合わせください。<br/>ありがとうございます！<br/>--------------------------------------<br/><br/>Xin chào,<br/><br/>Đây là mail gửi từ hệ thống Đánh giá hợp đồng lao động của Công ty TNHH Công nghiệp Brother Việt Nam (LCES)。<br/>Hệ thống thông báo có <span style='color: red; font-weight: bold;'>${rejectedRequests.length} yêu cầu đánh giá BỊ TỪ CHỐI</span>.<br/><br/><table border='1' cellpadding='5' cellspacing='0' style='width: 100%;'><thead><tr style='background-color: #f2f2f2;'><th>Loại đánh giá</th><th>Mã đợt Phát hành</th><th>Mã Nhân viên</th><th>Lý do từ chối</th><th>Người từ chối</th><th>Loại từ chối</th></tr></thead><tbody>${buildTableRows()}</tbody></table><br/>Bạn vui lòng click vào đường link dưới đây để xác nhận lại:<br/><a href='$confirmLink'>Link xác nhận</a><br/><br/>※Email này được gửi tự động bởi hệ thống LCES, xin vui lòng không reply.<br/>Vui lòng liên lạc cho đảm nhiệm để xác nhận hiện trạng。<br/>Xin cảm ơn！""";
  }

  // thông báo sửa kết quả đánh giá
  static String getKetQuaEmailBody({
    required String confirmLink,
    required String ketquaOld,
    required String ketquaNew,
    required List<dynamic> rejectedRequests,
  }) {
    // Tạo hàng cho bảng từ danh sách các yêu cầu bị từ chối
    String buildTableRows() {
      return rejectedRequests.map((request) {
        return "<tr>"
            "<td>${request.vchRCodeApprover ?? 'N/A'}</td>"
            "<td>${request.vchRCodeApprover ?? 'N/A'}</td>"
            "<td>${request.vchREmployeeId ?? 'N/A'}</td>"
            "<td>$ketquaOld</td>"
            "<td>$ketquaNew</td>"
            "</tr>";
      }).join();
    }

    return """---------------------------<br/>こんにちは,<br/><br/>完了した契約評価結果の修正依頼があったことをお知らせいたします。</span>.<br/><br/><br/><table border='1' cellpadding='5' cellspacing='0' style='width: 100%;'><thead><tr style='background-color: #f2f2f2;'><th>評価契約類</th><th>発行コード</th><th>社員コード</th><th>修正前の結果</th><th>修正後の結果</th></tr></thead><tbody>${buildTableRows()}</tbody></table><br/>以下のリンクをクリックして、内容をご確認ください。<br/><a href='$confirmLink'>Confirmation Link</a><br/><br/>※このメールはLCESシステムから自動的に送付されたので、返事をしないで下さい。<br/>ご質問がある場合は、人事課の課長までお問い合わせください。<br/>--------------------------------------<br/><br/>Xin chào,<br/><br/>Hệ thống thông tin tới bạn Yêu cầu sửa đánh giá hợp đồng <span style='color: green; font-weight: bold;'>ĐÃ HOÀN THÀNH</span>.<br/><br/><br/><table border='1' cellpadding='5' cellspacing='0' style='width: 100%;'><thead><tr style='background-color: #f2f2f2;'><th>Loại đánh giá</th><th>Mã đợt Phát hành</th><th>Mã Nhân viên</th><th>Kết quả trước sửa</th><th>Kết quả sau sửa</th></tr></thead><tbody>${buildTableRows()}</tbody></table><br/>Bạn vui lòng click vào đường link dưới đây để xác nhận lại:<br/><a href='$confirmLink'>Link xác nhận</a><br/><br/>※Email này được gửi tự động bởi hệ thống LCES, xin vui lòng không reply.<br/>Vui lòng liên lạc cho đảm nhiệm để xác nhận hiện trạng.""";
  }
}
