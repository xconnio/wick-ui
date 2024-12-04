import "package:get/get.dart";
import "package:wick_ui/app/modules/profile/profile_binding.dart";
import "package:wick_ui/app/modules/profile/profile_view.dart";
import "package:wick_ui/app/modules/welcome/welcome_binding.dart";
import "package:wick_ui/app/modules/welcome/welcome_view.dart";
import "package:wick_ui/app/routes/app_routes.dart";

mixin AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.welcome,
      page: WelcomeView.new,
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: ProfileView.new,
      binding: ProfileBinding(),
    ),
  ];
}
