import "package:flutter/material.dart";
import "package:get/get.dart";
import 'package:wick_ui/app/routes/app_pages.dart';
import 'package:wick_ui/app/routes/app_routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.PROFILE,
      getPages: AppPages.routes,
    );
  }
}
