import "package:get/get.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";

class ActionBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize controllers for the default tab (tabKey = 0)
    Get.lazyPut<ActionController>(
      ActionController.new,
      tag: "action_0",
      fenix: true,
    );
  }
}
