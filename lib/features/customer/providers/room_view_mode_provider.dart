import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manual room-listing view mode shared by Customer Home and Search.
///
/// `false` = list ([ListingRow]), `true` = grid ([ListingCard] in 2/3 cols).
/// Defaults to list to preserve existing behavior; never auto-switches.
/// Kept as a handwritten [NotifierProvider] (no codegen) so it survives
/// navigation and both screens stay in sync without extra API calls.
class RoomViewModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setGrid(bool value) {
    if (state != value) state = value;
  }

  void toggle() => state = !state;
}

final roomViewModeProvider = NotifierProvider<RoomViewModeNotifier, bool>(
  RoomViewModeNotifier.new,
);
