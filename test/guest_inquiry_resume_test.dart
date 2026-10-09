import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merokotha/features/auth/providers/pending_inquiry_provider.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_bottom_cta.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/login_sheet.dart';

ListingModel _listing() => ListingModel(
  id: 'room-1',
  ownerId: 'owner-1',
  ownerName: 'Owner',
  title: 'Cozy room in Baneshwor',
  roomType: 'room',
  rentPerMonth: 8000,
  depositAmount: 8000,
  floor: 1,
  totalFloors: 3,
  furnishing: FurnishingType.furnished,
  facilities: const [],
  description: 'Bright room near the main road.',
  photoUrls: const [],
  availableFrom: DateTime(2026, 1, 1),
  status: ListingStatus.active,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets(
    'guest Message Owner stores the room and prompts Google sign-in',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: RoomBottomCTA(
                listing: _listing(),
                userAsync: const AsyncValue.data(null),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(pendingInquiryProvider), isNull);

      await tester.tap(find.text('Message owner'));
      await tester.pumpAndSettle();

      // Room remembered for post-auth resume + sign-in prompt shown.
      expect(container.read(pendingInquiryProvider)?.id, 'room-1');
      expect(find.byType(LoginSheet), findsOneWidget);
    },
  );

  test('pending inquiry intent clears', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pendingInquiryProvider.notifier).set(_listing());
    expect(container.read(pendingInquiryProvider)?.id, 'room-1');

    container.read(pendingInquiryProvider.notifier).clear();
    expect(container.read(pendingInquiryProvider), isNull);
  });
}
