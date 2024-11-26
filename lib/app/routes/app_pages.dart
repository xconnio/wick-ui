import 'package:get/get.dart';
import '../modules/welcome/welcome_binding.dart';
import '../modules/welcome/welcome_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile/profile_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.WELCOME,
      page: () => WelcomeView(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),
  ];
}
