import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/routes/app_pages.dart";
import "package:wick_ui/app/routes/app_routes.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.profile,
      getPages: AppPages.routes,
    );
  }
}
