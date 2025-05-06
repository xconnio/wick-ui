import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    required this.isActive,
    super.key,
    this.size = 12,
  });

  final bool isActive;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.greenAccent : Colors.grey,
        shape: BoxShape.circle,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.greenAccent.withAlpha((0.8 * 255).round()),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>("isActive", isActive))
      ..add(DoubleProperty("size", size));
  }
}
