import "package:get/get.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";

class ClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientController>(ClientController.new);
  }
}
