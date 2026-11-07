import 'package:flutter/material.dart';

/// Shown instead of the app when Firebase could not be initialised.
class FirebaseSetupErrorApp extends StatelessWidget {
  final String error;
  const FirebaseSetupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase is not configured',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create a Firebase project, then run `flutterfire configure` '
                  'and rebuild the app. See the README for the full setup.',
                ),
                const SizedBox(height: 16),
                Text(error, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
