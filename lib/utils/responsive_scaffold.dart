import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:wick_ui/utils/main_drawer.dart";

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.body,
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final FloatingActionButton? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;
          return Scaffold(
            appBar: AppBar(
              title: Text(title ?? "Wick"),
              leading: leading,
              actions: trailing != null ? [trailing!] : null,
              automaticallyImplyLeading: !isDesktop, // Hide hamburger when sidebar is visible
            ),
            body: Row(
              children: [
                if (isDesktop)
                  const SizedBox(
                    width: 250,
                    child: MainDrawer(),
                  ),
                Expanded(child: body),
              ],
            ),
            drawer: !isDesktop ? const MainDrawer(isSidebar: false) : null,
            floatingActionButton: floatingActionButton,
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("title", title));
  }
}
