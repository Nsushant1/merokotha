import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merokotha/app.dart';
import 'package:merokotha/features/notification/notification_service.dart';
import 'package:merokotha/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to start MeroKotha. Please check your internet connection and try again.\n\nError: $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }

  // App Check must never crash startup: on release builds without a
  // registered SHA / Play Integrity setup, activate() can throw.
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity, // Change to .debug for testing
      appleProvider: AppleProvider.appAttest, // Change to .debug for testing
    );
  } catch (_) {
    // Continue without App Check.
  }

  await NotificationService().init();

  runApp(const ProviderScope(child: MeroKothaApp()));
}
