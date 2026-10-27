import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, customer, agent, superAdmin }

/// Agent privilege lifecycle, independent of [UserRole].
///
/// Every user can browse and post as themselves; only users whose application
/// was approved (`verified`) may use the separate Agent interface. The legacy
/// `role == agent && isVerified` combination is no longer consulted for
/// access — it is preserved on documents only for backward compatibility.
enum AgentStatus { none, pending, verified }

/// Name/photo projection of a user, mirrored in `usersPublic/{uid}`.
/// Also carries the public agent-directory fields (`bio`, contact numbers,
/// name-visibility) so the verified-agent directory can render without
/// touching private user documents.
class PublicProfile {
  final String uid;
  final String name;
  final String? photoUrl;
  final String? bio;
  final String? publicPhone;
  final String? whatsappNumber;
  final bool hideDisplayName;

  const PublicProfile({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.bio,
    this.publicPhone,
    this.whatsappNumber,
    this.hideDisplayName = false,
  });

  factory PublicProfile.fromMap(Map<String, dynamic> map, String uid) {
    return PublicProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      publicPhone: map['publicPhone'] as String?,
      whatsappNumber: map['whatsappNumber'] as String?,
      hideDisplayName: map['hideDisplayName'] as bool? ?? false,
    );
  }

  factory PublicProfile.fromSnapshot(DocumentSnapshot doc) =>
      PublicProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'name': name,
    'photoUrl': photoUrl,
    'bio': bio,
    'publicPhone': publicPhone,
    'whatsappNumber': whatsappNumber,
    'hideDisplayName': hideDisplayName,
  };

  /// Display name honoring the privacy flag.
  String get displayName => hideDisplayName ? 'Property Owner' : name;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final AgentStatus agentStatus;
  final String? photoUrl;
  final String? location;
  final String? fcmToken;

  /// Short public biography (agents show it on the directory profile).
  final String? bio;

  /// Optional separate public contact numbers (call / WhatsApp).
  final String? publicPhone;
  final String? whatsappNumber;

  /// When true, the public name is masked ("Property Owner").
  final bool hideDisplayName;

  /// 'en' | 'ne'. Synced so the language choice follows the account.
  final String locale;

  /// All registered device push tokens (multi-device support).
  /// [fcmToken] is retained as the most-recent token for backward
  /// compatibility with older readers.
  final List<String> fcmTokens;
  final bool isVerified;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    required this.phone,
    required this.role,
    this.agentStatus = AgentStatus.none,
    this.photoUrl,
    this.location,
    this.fcmToken,
    this.fcmTokens = const [],
    this.bio,
    this.publicPhone,
    this.whatsappNumber,
    this.hideDisplayName = false,
    this.locale = 'en',
    this.isVerified = false,
    this.isBanned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      agentStatus: AgentStatus.values.firstWhere(
        (e) => e.name == map['agentStatus'],
        orElse: () => AgentStatus.none,
      ),
      photoUrl: map['photoUrl'] as String?,
      location: map['location'] as String?,
      fcmToken: map['fcmToken'] as String?,
      bio: map['bio'] as String?,
      publicPhone: map['publicPhone'] as String?,
      whatsappNumber: map['whatsappNumber'] as String?,
      hideDisplayName: map['hideDisplayName'] as bool? ?? false,
      locale: map['locale'] as String? ?? 'en',
      fcmTokens:
          (map['fcmTokens'] as List?)?.whereType<String>().toList() ?? const [],
      isVerified: map['isVerified'] as bool? ?? false,
      isBanned: map['isBanned'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // To Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'agentStatus': agentStatus.name,
      'photoUrl': photoUrl,
      'location': location,
      'fcmToken': fcmToken,
      'fcmTokens': fcmTokens,
      'bio': bio,
      'publicPhone': publicPhone,
      'whatsappNumber': whatsappNumber,
      'hideDisplayName': hideDisplayName,
      'locale': locale,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    AgentStatus? agentStatus,
    String? photoUrl,
    String? location,
    String? fcmToken,
    List<String>? fcmTokens,
    String? bio,
    String? publicPhone,
    String? whatsappNumber,
    bool? hideDisplayName,
    String? locale,
    bool? isVerified,
    bool? isBanned,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      agentStatus: agentStatus ?? this.agentStatus,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      fcmToken: fcmToken ?? this.fcmToken,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      bio: bio ?? this.bio,
      publicPhone: publicPhone ?? this.publicPhone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      hideDisplayName: hideDisplayName ?? this.hideDisplayName,
      locale: locale ?? this.locale,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isOwner => role == UserRole.owner;
  bool get isAgent => role == UserRole.agent;
  bool get isAdmin => role == UserRole.superAdmin;

  /// Whether the user passed agent verification and may use the separate
  /// Agent interface. Derived from [agentStatus], never from [role].
  /// (Legacy documents may carry `role == agent && isVerified == true`;
  /// those users keep working only after an admin approves their
  /// application, which sets [agentStatus].)
  bool get isVerifiedAgent => agentStatus == AgentStatus.verified;

  /// A pending application blocks re-applying; a rejection allows it.
  bool get hasPendingAgentApplication => agentStatus == AgentStatus.pending;

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: ${role.name})';
}
