import "package:get/get.dart";

import "package:wick_ui/app/modules/action/action_controller.dart";

class ActionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActionController>(ActionController.new);
  }
}
