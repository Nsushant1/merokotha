import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// System-back handling for an entry-point page that can end up as the
/// bottom of the navigation stack (via `go`, the auth redirect, or a
/// deep link) — e.g. the login screen.
///
/// Unlike `GoRoute.onExit`, this only reacts to actual back-button pops:
/// programmatic `go()`/`push()` navigation (including post-login
/// redirects) is never intercepted, so it cannot loop or hijack flows.
///
/// Wrap ONLY stack-root entry pages with this (back always leaves them
/// for [homeRoute]). Do NOT wrap pushed detail pages — their normal pop
/// already returns to the previous screen.
///
/// Behavior on system back:
/// - Already at [homeRoute]: exits the app.
/// - Anywhere else: goes to [homeRoute] instead of closing the app.
class AppBackScope extends StatelessWidget {
  final String homeRoute;
  final Widget child;

  const AppBackScope({super.key, required this.homeRoute, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.state.uri.path == homeRoute) {
          SystemNavigator.pop();
        } else {
          router.go(homeRoute);
        }
      },
      child: child,
    );
  }
}
