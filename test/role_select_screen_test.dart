import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/presentation/screens/role_select_screen.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/widgets/promo_banner_carousel.dart';

/// Minimal router wiring just the routes this test needs.
GoRouter _buildRouter({String initialLocation = AppRoutes.roleSelect}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        builder: (_, _) => const Scaffold(body: Text('Landing')),
      ),
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (_, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const Scaffold(body: Text('Onboarding')),
      ),
    ],
  );
}

Widget _app(GoRouter router) {
  return ProviderScope(
    overrides: [authStateProvider.overrideWith((ref) => Stream.value(null))],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('role selection offers owner, room seeker and agent', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_buildRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectScreen), findsOneWidget);
    expect(find.text('House Owner'), findsOneWidget);
    expect(find.text('Room Seeker'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
  });

  testWidgets('back button from role selection returns to landing', (
    tester,
  ) async {
    final router = _buildRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Landing'), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.landing);
  });

  testWidgets('system back from role selection returns to landing', (
    tester,
  ) async {
    final router = _buildRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Landing'), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.landing);
  });

  testWidgets('back after being pushed from landing pops to landing', (
    tester,
  ) async {
    final router = _buildRouter(initialLocation: AppRoutes.landing);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(find.text('Landing'), findsOneWidget);

    router.push(AppRoutes.roleSelect);
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Landing'), findsOneWidget);
  });

  testWidgets('continue with no role selected stays on role selection', (
    tester,
  ) async {
    final router = _buildRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectScreen), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.roleSelect);
  });

  testWidgets('choosing a role then continue goes to login carrying the role', (
    tester,
  ) async {
    final router = _buildRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Room Seeker'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Not authenticated yet -> login first, role carried as `extra`.
    expect(find.text('Login'), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.login);
  });

  testWidgets('role selection screen does not render the promo banner', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_buildRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(PromoBannerCarousel), findsNothing);
  });

  testWidgets('backing out of login returns with selection cleared', (
    tester,
  ) async {
    final router = _buildRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    // Select a role and continue to login.
    await tester.tap(find.text('Room Seeker'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);

    // System back pops login -> role selection with nothing selected:
    // Continue is disabled so tapping it goes nowhere.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectScreen), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.roleSelect);
  });

  testWidgets('app back button clears selection when leaving', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('House Owner'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Landing'), findsOneWidget);

    // Fresh visit starts cleared: Continue stays disabled.
    router.push(AppRoutes.roleSelect);
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectScreen), findsOneWidget);
  });
}
