import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({required this.isActive, super.key});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade600 : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? "ACTIVE" : "INACTIVE",
          style: TextStyle(
            color: isActive ? Colors.green.shade600 : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>("isActive", isActive));
  }
}
