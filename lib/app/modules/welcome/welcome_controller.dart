import 'package:get/get.dart';

class WelcomeController extends GetxController {
  Future<void> navigateToProfile() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate animation duration
    Get.offNamed('/profile');
  }
}
