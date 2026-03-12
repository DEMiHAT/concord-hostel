import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/app_service.dart';
import 'services/mock_service.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

/// Toggle this flag to switch between demo (mock) and production (Firebase) mode.
/// Set to `false` once Firebase is fully configured.
const bool isDemo = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase when not in demo mode.
  if (!isDemo) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const HailmaryApp());
}

class HailmaryApp extends StatefulWidget {
  const HailmaryApp({super.key});

  @override
  State<HailmaryApp> createState() => _HailmaryAppState();
}

class _HailmaryAppState extends State<HailmaryApp> {
  late final AppService _service;

  @override
  void initState() {
    super.initState();
    // Select the service implementation based on the isDemo flag.
    if (isDemo) {
      _service = MockService();
    } else {
      _service = FirebaseService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H.A.I.L.M.A.R.Y.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SplashScreen(
        nextScreen: LoginScreen(service: _service),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => LoginScreen(service: _service),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => LoginScreen(service: _service),
            );
        }
      },
    );
  }
}
