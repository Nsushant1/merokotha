import 'package:cloud_firestore/cloud_firestore.dart';

/// Analytics event types. These names form the shared event schema with the
/// website — the web app must emit the same `type` strings into the same
/// `listingEvents` collection for combined dashboards:
///
/// - `view`: listing detail opened (visitorId = uid or anon session id)
/// - `inquiry`: inquiry sent on a listing
/// - `inquiry_accepted` / `inquiry_declined`: lister decision outcome
/// - `call`: public call button tapped
/// - `whatsapp`: WhatsApp button tapped
/// - `favourite`: listing favourited
enum AnalyticsEventType {
  view,
  inquiry,
  inquiryAccepted,
  inquiryDeclined,
  call,
  whatsapp,
  favourite,
}

/// One analytics event, stored at `listingEvents/{autoId}`.
class AnalyticsEvent {
  final String id;
  final String listingId;
  final String? ownerId;
  final AnalyticsEventType type;
  final String visitorId;
  final DateTime createdAt;

  const AnalyticsEvent({
    required this.id,
    required this.listingId,
    this.ownerId,
    required this.type,
    required this.visitorId,
    required this.createdAt,
  });

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map, String id) {
    return AnalyticsEvent(
      id: id,
      listingId: map['listingId'] as String? ?? '',
      ownerId: map['ownerId'] as String?,
      type: AnalyticsEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AnalyticsEventType.view,
      ),
      visitorId: map['visitorId'] as String? ?? 'anon',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AnalyticsEvent.fromSnapshot(DocumentSnapshot doc) =>
      AnalyticsEvent.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'listingId': listingId,
    'ownerId': ownerId,
    'type': type.name,
    'visitorId': visitorId,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

/// Aggregated stats for one listing over a time window.
class ListingStats {
  final String listingId;
  final int views;
  final int uniqueVisitors;
  final int inquiries;
  final int accepted;
  final int declined;
  final int calls;
  final int whatsapps;
  final int favourites;

  const ListingStats({
    required this.listingId,
    this.views = 0,
    this.uniqueVisitors = 0,
    this.inquiries = 0,
    this.accepted = 0,
    this.declined = 0,
    this.calls = 0,
    this.whatsapps = 0,
    this.favourites = 0,
  });

  int get pending => inquiries - accepted - declined;
}

/// One day-bucket of event counts for trend charts.
class TrendPoint {
  final DateTime day;
  final int views;
  final int inquiries;

  const TrendPoint({required this.day, this.views = 0, this.inquiries = 0});
}
