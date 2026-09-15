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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check must never crash startup: on release builds without a
  // registered SHA / Play Integrity setup, activate() can throw and would
  // otherwise silently break phone auth (OTP never arrives).
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity, // 🔁 Change to .debug for testing
      appleProvider: AppleProvider.appAttest, // 🔁 Change to .debug for testing
    );
  } catch (_) {
    // Continue without App Check; Firebase Auth will fall back to
    // reCAPTCHA verification so OTP can still be delivered.
  }

  await NotificationService().init();

  runApp(const ProviderScope(child: MeroKothaApp()));
}
