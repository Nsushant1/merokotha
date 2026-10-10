import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merokotha/app.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';

/// Smoke test for the app shell.
///
/// Replaces the `flutter create` counter test that previously lived here: it
/// asserted against a counter widget this project never had, so it had been
/// failing since the app was scaffolded.
void main() {
  testWidgets('the app boots and installs its router', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Firebase is not initialised in tests; the shell only needs auth to
        // resolve to "signed out" to pick the redirect.
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          currentUserProvider.overrideWith((ref) async => null),
        ],
        child: const MeroKothaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);

    // SplashScreen schedules a navigation timer on mount; let it fire, then
    // tear the tree down so the binding is not left holding a pending timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
