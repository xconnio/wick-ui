import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:xconn_ui/Providers/args_provider.dart";
import "package:xconn_ui/Providers/kwargs_provider.dart";
import "package:xconn_ui/responsive/responsive_layout.dart";
import "package:xconn_ui/screens/mobile/mobile_home.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ArgsProvider()),
        ChangeNotifierProvider(create: (context) => KwargsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: "Arial",
          useMaterial3: true,
        ),
        home: const ResponsiveLayout(
          mobileScaffold: MobileHomeScaffold(),
          tabletScaffold: MobileHomeScaffold(),
          desktopScaffold: MobileHomeScaffold(),
        ),
      ),
    );
  }
}
