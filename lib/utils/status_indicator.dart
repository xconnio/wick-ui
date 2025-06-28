import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    required this.isActive,
    this.size = 12,
    this.color,
    this.toolTipMsg,
    super.key,
  });

  final bool isActive;
  final double size;
  final Color? color;
  final String? toolTipMsg;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isActive ? Colors.greenAccent : Colors.grey);

    return Tooltip(
      message: toolTipMsg,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: effectiveColor,
          shape: BoxShape.circle,
          boxShadow: [
            if (isActive && color == null)
              BoxShadow(
                color: Colors.greenAccent.withAlpha((0.8 * 255).round()),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>("isActive", isActive))
      ..add(DoubleProperty("size", size))
      ..add(ColorProperty("color", color))
      ..add(StringProperty("toolTipMsg", toolTipMsg));
  }
}
