import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/welcome/welcome_controller.dart";

class WelcomeView extends StatelessWidget {
  WelcomeView({super.key});

  final WelcomeController controller = Get.find<WelcomeController>();

  @override
  Widget build(BuildContext context) {
    unawaited(controller.navigateToProfile());
    return const Scaffold(
      body: Center(
        child: Text("Welcome"),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<WelcomeController>("controller", controller));
  }
}
