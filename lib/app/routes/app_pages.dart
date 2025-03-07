import "package:get/get.dart";
import "package:wick_ui/app/modules/action/action_binding.dart";
import "package:wick_ui/app/modules/action/action_view.dart";
import "package:wick_ui/app/modules/profile/profile_binding.dart";
import "package:wick_ui/app/modules/profile/profile_view.dart";
import "package:wick_ui/app/modules/router/router_binding.dart";
import "package:wick_ui/app/modules/router/router_view.dart";
import "package:wick_ui/app/routes/app_routes.dart";

mixin AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.action,
      page: ActionView.new,
      binding: ActionBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: ProfileView.new,
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.router,
      page: RouterView.new,
      binding: RouterBinding(),
    ),
  ];
}
