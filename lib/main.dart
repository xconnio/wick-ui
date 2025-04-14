import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:wick_ui/app/modules/router/router_controller.dart";
import "package:wick_ui/app/routes/app_pages.dart";
import "package:wick_ui/app/routes/app_routes.dart";

void main() {
  Get
    ..put(RouterController(), permanent: true)
    ..put(ClientController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.action,
      getPages: AppPages.routes,
      initialBinding: BindingsBuilder(() {
        Get
          ..lazyPut<RouterController>(RouterController.new, fenix: true)
          ..lazyPut<ClientController>(ClientController.new, fenix: true);
      }),
    );
  }
}
