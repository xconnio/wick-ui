import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "package:wick_ui/config/theme/dark_theme_colors.dart";

class WampMethodButton extends StatelessWidget {
  const WampMethodButton({
    required this.selectedMethod,
    required this.methods,
    required this.onMethodChanged,
    required this.onMethodCalled,
    super.key,
  });

  final String? selectedMethod;
  final List<String> methods;
  final ValueChanged<String?> onMethodChanged;
  final VoidCallback onMethodCalled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150, // Reduced width for smaller size
      height: 40, // Reduced height for smaller size
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(DarkThemeColors.primaryColor),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 6, horizontal: 10), // Adjusted padding for smaller size
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        onPressed: onMethodCalled,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedMethod ?? "Call", // Default label
                style: const TextStyle(
                  color: DarkThemeColors.onPrimaryColor,
                  fontSize: 12, // Reduced font size for smaller button
                ),
                overflow: TextOverflow.ellipsis, // Avoid overflow issues
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.arrow_drop_down,
                color: DarkThemeColors.onPrimaryColor,
              ),
              color: DarkThemeColors.cardColor,
              tooltip: "Select a method", // Accessibility improvement
              onSelected: onMethodChanged,
              itemBuilder: (BuildContext context) {
                if (methods.isEmpty) {
                  return [
                    const PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        "No methods available",
                        style: TextStyle(color: DarkThemeColors.bodyTextColor),
                      ),
                    ),
                  ];
                }
                return methods.map((String method) {
                  return PopupMenuItem<String>(
                    value: method,
                    child: Text(
                      method,
                      style: const TextStyle(color: DarkThemeColors.bodyTextColor),
                    ),
                  );
                }).toList();
              },
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
      ..add(StringProperty("selectedMethod", selectedMethod))
      ..add(IterableProperty<String>("methods", methods))
      ..add(ObjectFlagProperty<ValueChanged<String?>>.has("onMethodChanged", onMethodChanged))
      ..add(ObjectFlagProperty<VoidCallback>.has("onMethodCalled", onMethodCalled));
  }
}
