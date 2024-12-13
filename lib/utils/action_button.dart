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
      width: 200,
      height: 50,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(DarkThemeColors.primaryColor),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
            Text(
              selectedMethod ?? "Call", // Show "Call" by default
              style: const TextStyle(
                color: DarkThemeColors.onPrimaryColor,
                fontSize: 14,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.arrow_drop_down,
                color: DarkThemeColors.onPrimaryColor,
              ),
              color: DarkThemeColors.cardColor,
              onSelected: onMethodChanged,
              itemBuilder: (BuildContext context) {
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
