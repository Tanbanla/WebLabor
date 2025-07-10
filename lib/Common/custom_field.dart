import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';

class CustomField extends StatelessWidget {
  final IconData icon;
  final bool obscureText;
  final String hinText;
  const CustomField({
    super.key,
    required this.icon,
    required this.obscureText,
    required this.hinText,
  });

  @override
  //
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width:  size.width/5,
      child:  TextField(
      cursorRadius: const Radius.circular(20),
      obscureText: obscureText,
      style: TextStyle(color: Common.blackColor),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        filled: true, // Bật nền fill
        fillColor: Common.greenColor.withOpacity(.2), // Màu nền
        prefixIcon: Icon(icon, color: Common.blackColor.withOpacity(.3)),
        hintText: hinText,
        border: OutlineInputBorder(
          // Sử dụng OutlineInputBorder thay vì InputBorder.none
          borderRadius: BorderRadius.circular(30), // Độ bo tròn
          borderSide: BorderSide.none, // Ẩn đường viền mặc định
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Common.blackColor.withOpacity(.5), // Màu viền khi focus
            width: 1.0,
          ),
        ),
      ),
      cursorColor: Common.blackColor.withOpacity(.5),
    )
    );
  }
}
