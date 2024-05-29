import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:xconn_ui/providers/args_provider.dart";
import "package:xconn_ui/providers/event_provider.dart";
import "package:xconn_ui/providers/invocation_provider.dart";
import "package:xconn_ui/providers/kwargs_provider.dart";
import "package:xconn_ui/providers/result_provider.dart";
import "package:xconn_ui/providers/session_states_provider.dart";
import "package:xconn_ui/responsive/responsive_layout.dart";
import "package:xconn_ui/screens/mobile/splash_screen.dart";

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
        ChangeNotifierProvider(create: (context) => InvocationProvider()),
        ChangeNotifierProvider(create: (context) => EventProvider()),
        ChangeNotifierProvider(create: (context) => ResultProvider()),
        ChangeNotifierProvider(create: (context) => SessionStateProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: "Arial",
          useMaterial3: true,
        ),
        home: const ResponsiveLayout(
          mobileScaffold: SplashScreen(),
          tabletScaffold: SplashScreen(),
          desktopScaffold: SplashScreen(),
        ),
      ),
    );
  }
}
