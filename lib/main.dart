import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/firebase_setup_error_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // The app needs a real Firebase project. If initialisation fails (or the
  // placeholder options from the template are still in place) show a clear
  // setup message instead of silently running without a backend.
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.contains('Demo') || options.appId.contains('demo')) {
      throw StateError(
        'firebase_options.dart still contains placeholder values. '
        'Run `flutterfire configure` to connect your Firebase project.',
      );
    }
    await Firebase.initializeApp(options: options);
  } catch (e) {
    runApp(FirebaseSetupErrorApp(error: e.toString()));
    return;
  }

  runApp(const CampusReportApp());
}

class CampusReportApp extends StatelessWidget {
  const CampusReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        // IncidentProvider follows the sign-in state: it starts listening to
        // Firestore after login and clears everything after logout.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(),
          update: (_, auth, incidents) {
            incidents!.onAuthChanged(isAuthenticated: auth.isAuthenticated);
            return incidents;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
