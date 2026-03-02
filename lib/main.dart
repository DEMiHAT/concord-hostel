import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'services/mock_service.dart';
import 'screens/login_screen.dart';

void main() {
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

  // NOTE: Firebase initialization is commented out for demo mode.
  // Uncomment and configure when Firebase is set up:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const ConcordApp());
}

class ConcordApp extends StatefulWidget {
  const ConcordApp({super.key});

  @override
  State<ConcordApp> createState() => _ConcordAppState();
}

class _ConcordAppState extends State<ConcordApp> {
  final MockService _mockService = MockService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C.O.N.C.O.R.D.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: LoginScreen(service: _mockService),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => LoginScreen(service: _mockService),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => LoginScreen(service: _mockService),
            );
        }
      },
    );
  }
}
