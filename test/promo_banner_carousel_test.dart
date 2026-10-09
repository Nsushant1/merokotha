import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/shared/widgets/promo_banner_carousel.dart';

Widget _host({
  List<PromoBannerDestination>? destinations,
  double height = 148,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PromoBannerCarousel(
        destinations: destinations ?? promoBannerDestinations,
        height: height,
      ),
    ),
  );
}

/// The active dot is painted in [AppColors.primary]; inactive dots are grey.
bool _isActiveDot(WidgetTester tester, int index) {
  final decoration =
      tester
              .widget<AnimatedContainer>(
                find.byType(AnimatedContainer).at(index),
              )
              .decoration
          as BoxDecoration;
  return decoration.color == AppColors.primary;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('shows the first promo artwork full-bleed', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.byType(PageView), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image).first);
    expect((image.image as AssetImage).assetName, 'assets/kitta.png');
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('swiping to the next page swaps to the second artwork', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _settle(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await _settle(tester);

    final image = tester.widget<Image>(find.byType(Image).last);
    expect((image.image as AssetImage).assetName, 'assets/himavolt.png');
  });

  testWidgets('dot indicator is shown for multiple destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _settle(tester);

    expect(find.byType(AnimatedContainer), findsNWidgets(2));
    expect(_isActiveDot(tester, 0), isTrue);
    expect(_isActiveDot(tester, 1), isFalse);
  });

  testWidgets('auto-advances to the next banner every 3 seconds', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _settle(tester);

    expect(_isActiveDot(tester, 0), isTrue);

    // First auto-advance.
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(_isActiveDot(tester, 0), isFalse);
    expect(_isActiveDot(tester, 1), isTrue);

    // Wraps back to the first banner on the next tick.
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(_isActiveDot(tester, 0), isTrue);
    expect(_isActiveDot(tester, 1), isFalse);
  });

  testWidgets('empty destination list collapses to nothing', (tester) async {
    await tester.pumpWidget(_host(destinations: []));

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('single destination hides the indicator and never scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(destinations: promoBannerDestinations.take(1).toList()),
    );
    await _settle(tester);

    expect(find.byType(AnimatedContainer), findsNothing);

    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });

  group('InFeedPromoCarousel (custom Pitambari / Floor Cleaner designs)', () {
    Future<void> pumpInFeed(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InFeedPromoCarousel())),
      );
    }

    testWidgets('shows the custom Pitambari banner first', (tester) async {
      await pumpInFeed(tester);

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Pitambari'), findsOneWidget);
      expect(
        find.text('Herbal care rooted in Nepali tradition'),
        findsOneWidget,
      );
      expect(find.text('Explore'), findsOneWidget);
      expect(find.byIcon(Icons.spa_rounded), findsOneWidget);
      // Second banner is offstage until swiped.
      expect(find.text('Floor Cleaner'), findsNothing);
    });

    testWidgets('swiping swaps to the Floor Cleaner banner', (tester) async {
      await pumpInFeed(tester);
      await _settle(tester);

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await _settle(tester);

      expect(find.text('Floor Cleaner'), findsOneWidget);
      expect(find.text('Spotless shine for every room'), findsOneWidget);
      expect(find.text('Shop now'), findsOneWidget);
      expect(find.byIcon(Icons.cleaning_services_rounded), findsOneWidget);
    });

    testWidgets('auto-advances every 3 seconds', (tester) async {
      await pumpInFeed(tester);
      await _settle(tester);

      expect(find.text('Pitambari'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await _settle(tester);

      expect(find.text('Floor Cleaner'), findsOneWidget);
    });
  });
}
