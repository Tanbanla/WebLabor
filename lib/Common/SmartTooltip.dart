import 'package:flutter/material.dart';

class SmartTooltip extends StatefulWidget {
  final String text;
  final Widget child;
  
  SmartTooltip({required this.text, required this.child});
  
  @override
  _SmartTooltipState createState() => _SmartTooltipState();
}

class _SmartTooltipState extends State<SmartTooltip> {
  OverlayEntry? _tooltipEntry;
  final GlobalKey _childKey = GlobalKey();

  void _showTooltip() {
    if (_tooltipEntry != null) return;
    
    final renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    _tooltipEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy, // Ngay dưới widget
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          child: Container(
            width: size.width > 300 ? size.width : 300, // Chiều rộng tối thiểu
            //constraints: BoxConstraints(maxHeight: 200),
            padding: EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Text(
                widget.text,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_tooltipEntry!);
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showTooltip(),
      onExit: (_) => _hideTooltip(),
      child: KeyedSubtree(
        key: _childKey,
        child: widget.child,
      ),
    );
  }
}