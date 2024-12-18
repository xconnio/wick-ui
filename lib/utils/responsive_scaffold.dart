import "dart:io";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:wick_ui/utils/main_drawer.dart";

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.body,
    super.key,
    this.title,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final FloatingActionButton? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopOrWeb = kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    final bool shouldStickDrawer = isDesktopOrWeb && screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? "Wick"),
      ),
      body: Row(
        children: [
          if (shouldStickDrawer)
            const SizedBox(
              width: 250,
              child: MainDrawer(),
            ),
          Expanded(
            child: body,
          ),
        ],
      ),
      drawer: shouldStickDrawer ? null : const MainDrawer(),
      floatingActionButton: floatingActionButton,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("title", title));
  }
}
