import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/agent/presentation/screens/agent_home_screen.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/presentation/screens/customer_home_screen.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/landing/presentation/screens/landing_screen.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_category_row.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_search_bar.dart';
import 'package:merokotha/shared/widgets/mk_search_field.dart';
import 'package:merokotha/shared/widgets/mk_state_widgets.dart';
import 'package:merokotha/features/owner/presentation/screens/owner_home_screen.dart';
import 'package:merokotha/features/owner/providers/owner_providers.dart';
import 'package:merokotha/shared/widgets/promo_banner_carousel.dart';

/// Overrides every backend-backed provider the four home screens watch, so
/// the screens can be rendered without Firebase.
ProviderScope _scope(Widget child) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      currentUserProvider.overrideWith((ref) async => null),
      activeListingsProvider.overrideWith((ref) => Stream.value(const [])),
      favouriteIdsProvider.overrideWith((ref) => Stream.value(const [])),
      ownerListingsProvider.overrideWith((ref) => Stream.value(const [])),
      pendingInquiryCountProvider.overrideWith((ref) => Stream.value(0)),
    ],
    child: child,
  );
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: '/:rest',
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );

  await tester.pumpWidget(_scope(MaterialApp.router(routerConfig: router)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Banner top must sit at or below [above]'s bottom, and its own bottom at
/// or above [below]'s top — i.e. it is sandwiched directly between the two.
void _expectBannerBetween(
  WidgetTester tester, {
  required Finder above,
  required Finder below,
}) {
  final banner = find.byType(PromoBannerCarousel);
  expect(banner, findsOneWidget);
  expect(
    tester.getTopLeft(banner).dy,
    greaterThanOrEqualTo(tester.getBottomLeft(above).dy),
    reason: 'banner must render below $above',
  );
  expect(
    tester.getBottomLeft(banner).dy,
    lessThanOrEqualTo(tester.getTopLeft(below).dy),
    reason: 'banner must render above $below',
  );
}

void main() {
  testWidgets('landing screen shows the promo banner below the search bar', (
    tester,
  ) async {
    await _pumpScreen(tester, const LandingScreen());

    _expectBannerBetween(
      tester,
      above: find.byType(LandingSearchBar),
      below: find.byType(LandingCategoryRow),
    );
  });

  testWidgets('customer home shows the promo banner below the search bar', (
    tester,
  ) async {
    await _pumpScreen(tester, const CustomerHomeScreen());

    _expectBannerBetween(
      tester,
      above: find.byType(MkSearchField),
      below: find.byType(MkEmptyState),
    );
  });

  testWidgets('owner home shows the promo banner below the greeting header', (
    tester,
  ) async {
    await _pumpScreen(tester, const OwnerHomeScreen());

    // Sits between the greeting header and the stats/quick-actions block.
    expect(
      tester.getTopLeft(find.byType(PromoBannerCarousel)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Owner')).dy),
    );
    expect(
      tester.getBottomLeft(find.byType(PromoBannerCarousel)).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('Quick actions')).dy),
    );
  });

  testWidgets('agent home shows the promo banner below the greeting', (
    tester,
  ) async {
    await _pumpScreen(tester, const AgentHomeScreen());

    // Between the greeting block and the quick-action grid.
    expect(
      tester.getBottomLeft(find.byType(PromoBannerCarousel)).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('Post a room')).dy),
    );
  });
}
