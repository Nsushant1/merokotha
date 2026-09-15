import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, customer, agent, superAdmin }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? photoUrl;
  final String? location;
  final String? fcmToken;
  final bool isVerified;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.location,
    this.fcmToken,
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
      phone: map['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      photoUrl: map['photoUrl'] as String?,
      location: map['location'] as String?,
      fcmToken: map['fcmToken'] as String?,
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
      'phone': phone,
      'role': role.name,
      'photoUrl': photoUrl,
      'location': location,
      'fcmToken': fcmToken,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    UserRole? role,
    String? photoUrl,
    String? location,
    String? fcmToken,
    bool? isVerified,
    bool? isBanned,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      fcmToken: fcmToken ?? this.fcmToken,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isOwner => role == UserRole.owner;
  bool get isCustomer => role == UserRole.customer;
  bool get isAgent => role == UserRole.agent;
  bool get isAdmin => role == UserRole.superAdmin;

  /// Owner or agent — both can list rooms and handle inquiries.
  bool get isLister => isOwner || isAgent;

  /// Admin-verified agent. Becoming an agent requires admin verification
  /// (see plan); unverified agents can browse but cannot post.
  bool get isVerifiedAgent => isAgent && isVerified;

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: ${role.name})';
}
