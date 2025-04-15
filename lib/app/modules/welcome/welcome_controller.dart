import "package:get/get.dart";

class WelcomeController extends GetxController {
  Future<void> navigateToClient() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate animation duration
    await Get.offNamed("/client");
  }
}
