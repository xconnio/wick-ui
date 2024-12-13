import "package:flutter/material.dart";
import "package:get/get.dart";

class ArgsController extends GetxController {
  RxList<TextEditingController> controllers = <TextEditingController>[].obs;

  @override
  void onInit() {
    controllers.add(TextEditingController());
    super.onInit();
  }

  void addController() {
    controllers.add(TextEditingController());
  }

  void removeController(int index) {
    if (controllers.length > 1) {
      final controller = controllers[index];
      controllers.removeAt(index);
      controller.dispose();
    }
  }

  @override
  void onClose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
