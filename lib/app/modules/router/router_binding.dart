import "package:get/get.dart";

import "package:wick_ui/app/modules/router/router_controller.dart";

class RouterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RouterController>(RouterController.new);
  }
}
