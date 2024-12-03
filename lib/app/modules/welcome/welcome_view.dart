import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/welcome/welcome_controller.dart";

class WelcomeView extends StatelessWidget {
  final WelcomeController controller = Get.find<WelcomeController>();

  @override
  Widget build(BuildContext context) {
    controller.navigateToProfile();
    return Scaffold(
      body: Center(
        child: Text("Welcome"),
      ),
    );
  }
}
