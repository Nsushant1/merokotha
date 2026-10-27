import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/models/analytics_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

/// Cap on events pulled for client-side aggregation. Dashboards aggregate
/// in memory; for very large platforms this should move to Cloud Functions
/// rollups reading the same `listingEvents` collection.
const int kAnalyticsFetchLimit = 2000;

/// Visitor identity: the Firebase uid when signed in, otherwise a per-launch
/// anonymous session id. Stable anonymous tracking across launches can be
/// added with `shared_preferences` without changing the event schema.
class VisitorIdentity {
  static String _sessionId = '';
  static String get sessionId {
    if (_sessionId.isEmpty) {
      _sessionId =
          'anon_${DateTime.now().microsecondsSinceEpoch}_${(_sessionId.hashCode & 0xffff).toRadixString(16)}';
    }
    return _sessionId;
  }
}

class AnalyticsRepository {
  final FirebaseFirestore _db;
  AnalyticsRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('listingEvents');

  /// Best-effort event log — analytics must never break the user flow.
  Future<void> logEvent({
    required String listingId,
    String? ownerId,
    required AnalyticsEventType type,
    required String visitorId,
  }) async {
    try {
      await _events.add({
        'listingId': listingId,
        'ownerId': ownerId,
        'type': type.name,
        'visitorId': visitorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore — analytics is non-critical.
    }
  }

  Future<List<AnalyticsEvent>> fetchOwnerEvents(
    String ownerId, {
    DateTime? since,
  }) async {
    var q = _events
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .limit(kAnalyticsFetchLimit);
    final snap = await q.get();
    final events = snap.docs.map(AnalyticsEvent.fromSnapshot).toList();
    if (since == null) return events;
    return events.where((e) => e.createdAt.isAfter(since)).toList();
  }

  Future<List<AnalyticsEvent>> fetchAllEvents({DateTime? since}) async {
    final snap = await _events
        .orderBy('createdAt', descending: true)
        .limit(kAnalyticsFetchLimit)
        .get();
    final events = snap.docs.map(AnalyticsEvent.fromSnapshot).toList();
    if (since == null) return events;
    return events.where((e) => e.createdAt.isAfter(since)).toList();
  }
}

/// Pure aggregation helpers (testable without Firestore).
Map<String, ListingStats> aggregateByListing(List<AnalyticsEvent> events) {
  final visitors = <String, Set<String>>{};
  final stats = <String, _MutableStats>{};
  for (final e in events) {
    if (e.listingId.isEmpty) continue;
    final s = stats.putIfAbsent(e.listingId, _MutableStats.new);
    visitors.putIfAbsent(e.listingId, () => <String>{}).add(e.visitorId);
    switch (e.type) {
      case AnalyticsEventType.view:
        s.views++;
        break;
      case AnalyticsEventType.inquiry:
        s.inquiries++;
        break;
      case AnalyticsEventType.inquiryAccepted:
        s.accepted++;
        break;
      case AnalyticsEventType.inquiryDeclined:
        s.declined++;
        break;
      case AnalyticsEventType.call:
        s.calls++;
        break;
      case AnalyticsEventType.whatsapp:
        s.whatsapps++;
        break;
      case AnalyticsEventType.favourite:
        s.favourites++;
        break;
    }
  }
  return {
    for (final id in stats.keys)
      id: ListingStats(
        listingId: id,
        views: stats[id]!.views,
        uniqueVisitors: visitors[id]!.length,
        inquiries: stats[id]!.inquiries,
        accepted: stats[id]!.accepted,
        declined: stats[id]!.declined,
        calls: stats[id]!.calls,
        whatsapps: stats[id]!.whatsapps,
        favourites: stats[id]!.favourites,
      ),
  };
}

class _MutableStats {
  int views = 0;
  int inquiries = 0;
  int accepted = 0;
  int declined = 0;
  int calls = 0;
  int whatsapps = 0;
  int favourites = 0;
}

/// Daily view/inquiry counts for the last [days] days (oldest → newest).
List<TrendPoint> buildTrend(List<AnalyticsEvent> events, int days) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(
    Duration(days: days - 1),
  );
  final views = List<int>.filled(days, 0);
  final inquiries = List<int>.filled(days, 0);
  for (final e in events) {
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    final idx = d.difference(start).inDays;
    if (idx < 0 || idx >= days) continue;
    if (e.type == AnalyticsEventType.view) {
      views[idx]++;
    } else if (e.type == AnalyticsEventType.inquiry) {
      inquiries[idx]++;
    }
  }
  return List.generate(
    days,
    (i) => TrendPoint(
      day: start.add(Duration(days: i)),
      views: views[i],
      inquiries: inquiries[i],
    ),
  );
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Resolves the visitor id for event logging.
final visitorIdProvider = Provider<String>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  return uid ?? VisitorIdentity.sessionId;
});

/// Owner dashboard events (last 30 days).
final ownerAnalyticsProvider = FutureProvider<List<AnalyticsEvent>>((
  ref,
) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const <AnalyticsEvent>[];
  return ref
      .watch(analyticsRepositoryProvider)
      .fetchOwnerEvents(
        user.uid,
        since: DateTime.now().subtract(const Duration(days: 30)),
      );
});

/// Admin dashboard events (last 30 days).
final platformAnalyticsProvider = FutureProvider<List<AnalyticsEvent>>((
  ref,
) async {
  return ref
      .watch(analyticsRepositoryProvider)
      .fetchAllEvents(since: DateTime.now().subtract(const Duration(days: 30)));
});
