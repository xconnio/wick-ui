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
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? "Wick"),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= 800) {
            // Desktop/Web layout
            return Row(
              children: [
                const SizedBox(
                  width: 250,
                  child: MainDrawer(),
                ),
                Expanded(child: body),
              ],
            );
          } else {
            // Mobile/Tablet layout
            return body;
          }
        },
      ),
      drawer: const MainDrawer(isSidebar: false),
      floatingActionButton: floatingActionButton,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("title", title));
  }
}
