import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:wick_ui/config/theme/dark_theme_colors.dart";
import "package:wick_ui/config/theme/my_fonts.dart";

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
      width: 150,
      height: 40,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(DarkThemeColors.buttonBackground),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          elevation: WidgetStateProperty.all(2),
        ),
        onPressed: onMethodCalled,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedMethod ?? "Call",
                style: MyFonts.bodyMedium.copyWith(
                  fontSize: 12,
                  color: DarkThemeColors.buttonForeground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.arrow_drop_down,
                color: DarkThemeColors.buttonForeground,
              ),
              color: DarkThemeColors.cardColor,
              tooltip: "Select a method",
              onSelected: onMethodChanged,
              itemBuilder: (BuildContext context) {
                if (methods.isEmpty) {
                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        "No methods available",
                        style: MyFonts.bodyMedium.copyWith(
                          color: DarkThemeColors.textPrimary.withAlpha((0.6 * 255).round()),
                        ),
                      ),
                    ),
                  ];
                }
                return methods.map((String method) {
                  return PopupMenuItem<String>(
                    value: method,
                    child: Text(
                      method,
                      style: MyFonts.bodyMedium.copyWith(
                        color: DarkThemeColors.textPrimary,
                      ),
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
