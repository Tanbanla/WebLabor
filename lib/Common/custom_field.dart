import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_labor_contract/Common/common.dart';

class CustomField extends StatelessWidget {
  final TextEditingController? controller;
  final IconData icon;
  final bool obscureText;
  final String hinText;
  final String? Function(String?)? validator;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final Radius? cursorRadius;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const CustomField({
    super.key,
    this.controller,
    required this.icon,
    required this.obscureText,
    required this.hinText,
    this.validator,
    this.textStyle,
    this.cursorColor,
    this.cursorRadius,
    this.decoration,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      width: math.max(size.width / 5, 350),
      constraints: const BoxConstraints(minWidth: 350),
      child: TextFormField(
        // Đổi từ TextField sang TextFormField để hỗ trợ validator
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: textStyle ?? TextStyle(color: Common.blackColor),
        cursorRadius: cursorRadius ?? const Radius.circular(20),
        cursorColor: cursorColor ?? Common.blackColor.withOpacity(.5),
        decoration:
            decoration ??
            InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ),
              filled: true,
              fillColor: Common.greenColor.withOpacity(.2),
              prefixIcon: Icon(
                icon,
                color: Common.blackColor.withOpacity(.3),
                size: 20,
              ),
              hintText: hinText,
              hintStyle: TextStyle(
                color: Common.blackColor.withOpacity(.4),
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
                gapPadding: 4,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Common.blackColor.withOpacity(.5),
                  width: 1.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                // style cho lỗi validation
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                // style khi có lỗi và focus
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
      ),
    );
  }
}

/// Custom Field 2
class CustomField1 extends StatelessWidget {
  final IconData icon;
  final bool obscureText;
  final String hinText;
  const CustomField1({
    super.key,
    required this.icon,
    required this.obscureText,
    required this.hinText,
  });

  @override
  //
  Widget build(BuildContext context) {
    //Size size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      width: 200,
      child: TextField(
        cursorRadius: const Radius.circular(20),
        obscureText: obscureText,
        style: TextStyle(color: Common.blackColor),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
          filled: true, // Bật nền fill
          fillColor:
              Colors.white, //Common.greenColor.withOpacity(.2), // Màu nền
          // prefixIcon: Icon(icon, color: Common.blackColor.withOpacity(.3)),
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
      ),
    );
  }
}

// dialog thông báo common
class DialogNotification extends StatefulWidget {
  final String message;
  final String title;
  final IconData icon;
  final Color color;
  const DialogNotification({
    required this.message,
    required this.icon,
    required this.color,
    required this.title,
    super.key,
  });

  @override
  State<DialogNotification> createState() => _DialogNotificationState();
}

class _DialogNotificationState extends State<DialogNotification> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(widget.icon, color: widget.color, size: 50),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(widget.message), const SizedBox(height: 10)],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
          ),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
class CompactReadOnlyField extends StatelessWidget {
  final String value;
  final String label;
  final double? width;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const CompactReadOnlyField({
    Key? key,
    required this.value,
    required this.label,
    this.width,
    this.labelStyle,
    this.valueStyle,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: labelStyle ?? TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor ?? Colors.grey[300]!),
            ),
            child: Text(
              value,
              style: valueStyle ?? TextStyle(
                fontSize: 14, 
                color: Colors.grey[800]
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Custom nhập dữ liệu
class BuildCompactTextField extends StatelessWidget {
  final String? initialValue;
  final String label;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool readOnly;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const BuildCompactTextField({
    Key? key,
    this.initialValue,
    required this.label,
    this.onChanged,
    this.keyboardType,
    this.maxLines,
    this.readOnly = false,
    this.validator,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14)
    );
  }
}
//   class BuildCompactTextField extends StatefulWidget {
//   final String? initialValue;
//   final String label;
//   final Function(String) onChanged;
//   final TextInputType? keyboardType;
//   final int? maxLines;

//   const BuildCompactTextField({
//     super.key, 
//     this.initialValue, 
//     required this.label, 
//     required this.onChanged, 
//     this.keyboardType, 
//     this.maxLines
//   });

//   @override
//   State<BuildCompactTextField> createState() => _BuildCompactTextFieldState();
// }

// class _BuildCompactTextFieldState extends State<BuildCompactTextField> {
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       initialValue: widget.initialValue,
//       decoration: InputDecoration(
//         labelText: widget.label, // Sửa từ widget.initialValue thành widget.label
//         isDense: true,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 12,
//           vertical: 12,
//         ),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         floatingLabelBehavior: FloatingLabelBehavior.auto,
//       ),
//       style: const TextStyle(fontSize: 14),
//       keyboardType: widget.keyboardType,
//       maxLines: widget.maxLines,
//       onChanged: widget.onChanged,
//     );
//   }
// }