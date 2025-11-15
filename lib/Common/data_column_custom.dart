import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

// DataColumn2 custom
class DataColumnCustom extends StatelessWidget {
  final String title;
  final double? fontSize;
  final double? width;
  final TextAlign? textAlign;
  final Color? textColor;
  final FontWeight? fontWeight;
  final bool numeric;
  final bool showSortIcon;
  final bool fixedWidth;
  final int? maxLines;
  final double? verticalPadding;
  final double? horizontalPadding;
  final void Function(int, bool)? onSort; // Added onSort property

  const DataColumnCustom({
    super.key,
    required this.title,
    this.fontSize = 14,
    this.width,
    this.textAlign,
    this.textColor,
    this.fontWeight = FontWeight.bold,
    this.numeric = false,
    this.showSortIcon = false,
    this.fixedWidth = true,
    this.maxLines = 2,
    this.verticalPadding = 4,
    this.horizontalPadding = 8,
    this.onSort, // Added to constructor
  });

  DataColumn2 toDataColumn2() {
    // Ensure width is respected even when rendered in a plain DataTable (fallback scenario)
    final labelChild = SizedBox(
      width: fixedWidth ? width : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding!,
          horizontal: horizontalPadding!,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor ?? Colors.black,
            fontWeight: fontWeight,
            height: 1.3,
          ),
          textAlign: textAlign ?? TextAlign.center,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ),
    );
    return DataColumn2(
      label: labelChild,
      size: fixedWidth ? ColumnSize.S : ColumnSize.L,
      fixedWidth: fixedWidth ? width : null,
      numeric: numeric,
      tooltip: maxLines != null && maxLines! > 1 ? title : null,
      onSort: onSort,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
