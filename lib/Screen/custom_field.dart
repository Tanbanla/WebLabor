import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';
class CustomField extends StatelessWidget {
  final IconData icon;
  final bool obscureText;
  final String hinText;
  const CustomField({
    super.key,required this.icon, required this.obscureText, required this.hinText
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorRadius: Radius.circular(20),
      obscureText: obscureText,
      style: TextStyle(
        color: Common.blackColor,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixIcon: Icon(
          icon,
          color: Common.blackColor.withOpacity(.3),
        ),
        hintText: hinText,
      ),
      cursorColor: Common.blackColor.withOpacity(.5),
    );
  }
}