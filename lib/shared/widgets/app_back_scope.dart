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
/// Wrap ONLY pages that can sit at the bottom of the stack (reached via
/// `go`, the auth redirect, or a deep link). Do NOT wrap pushed detail
/// pages — their normal pop already returns to the previous screen.
/// Set [popWhenPossible] when the page is also pushed onto a non-empty
/// stack, so back returns to the pusher in that case.
///
/// Behavior on system back:
/// - Already at [homeRoute]: exits the app.
/// - Anywhere else: goes to [homeRoute] instead of closing the app.
class AppBackScope extends StatelessWidget {
  final String homeRoute;
  final Widget child;

  /// When true and this page was pushed onto a non-empty stack, back pops
  /// normally (returning to the page that pushed it) instead of jumping to
  /// [homeRoute]. Keeps [homeRoute] semantics for the stack-root case.
  final bool popWhenPossible;

  /// Optional callback invoked when system back reroutes to [homeRoute]
  /// (not on a normal pop). Use it to reset page-local state that must
  /// not survive leaving the page.
  final VoidCallback? onBeforeHome;

  const AppBackScope({
    super.key,
    required this.homeRoute,
    required this.child,
    this.popWhenPossible = false,
    this.onBeforeHome,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: popWhenPossible && Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.state.uri.path == homeRoute) {
          SystemNavigator.pop();
        } else {
          onBeforeHome?.call();
          router.go(homeRoute);
        }
      },
      child: child,
    );
  }
}
