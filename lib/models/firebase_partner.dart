import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnershipStatus { pending, accepted, declined, blocked }
enum InvitationType { appUser, smsInvite }

class FirebasePartner {
  final String id;
  final String requesterId; // User who sent the partner request
  final String recipientId; // User who received the request (empty for SMS invites)
  final String? recipientEmail; // For SMS invites, store email for later linking
  final String? recipientPhone; // Phone number for SMS invites
  final String? recipientName; // Name from contacts
  final PartnershipStatus status;
  final InvitationType type;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? inviteToken; // Unique token for SMS invites
  final List<String> sharedGoalIds; // Goals they're partnered on
  final Map<String, dynamic> metadata; // Additional data (contact info, etc.)

  FirebasePartner({
    required this.id,
    required this.requesterId,
    this.recipientId = '',
    this.recipientEmail,
    this.recipientPhone,
    this.recipientName,
    this.status = PartnershipStatus.pending,
    this.type = InvitationType.appUser,
    required this.createdAt,
    this.respondedAt,
    this.inviteToken,
    this.sharedGoalIds = const [],
    this.metadata = const {},
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'recipientId': recipientId,
      'recipientEmail': recipientEmail,
      'recipientPhone': recipientPhone,
      'recipientName': recipientName,
      'status': status.name,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'inviteToken': inviteToken,
      'sharedGoalIds': sharedGoalIds,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory FirebasePartner.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebasePartner(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientEmail: data['recipientEmail'],
      recipientPhone: data['recipientPhone'],
      recipientName: data['recipientName'],
      status: PartnershipStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PartnershipStatus.pending,
      ),
      type: InvitationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => InvitationType.appUser,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate() 
          : null,
      inviteToken: data['inviteToken'],
      sharedGoalIds: List<String>.from(data['sharedGoalIds'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Check if partnership is active
  bool get isActive => status == PartnershipStatus.accepted;

  // Check if it's a pending SMS invite
  bool get isPendingSmsInvite => 
      type == InvitationType.smsInvite && status == PartnershipStatus.pending;

  // Get display name for the partner
  String getDisplayName(String currentUserId) {
    if (recipientName != null && recipientName!.isNotEmpty) {
      return recipientName!;
    }
    if (recipientEmail != null && recipientEmail!.isNotEmpty) {
      return recipientEmail!;
    }
    if (recipientPhone != null && recipientPhone!.isNotEmpty) {
      return recipientPhone!;
    }
    return 'Unknown Partner';
  }

  // Get partner ID (the other user's ID)
  String getPartnerId(String currentUserId) {
    return currentUserId == requesterId ? recipientId : requesterId;
  }

  // Copy with method for updates
  FirebasePartner copyWith({
    String? recipientId,
    String? recipientEmail,
    String? recipientPhone,
    String? recipientName,
    PartnershipStatus? status,
    InvitationType? type,
    DateTime? respondedAt,
    String? inviteToken,
    List<String>? sharedGoalIds,
    Map<String, dynamic>? metadata,
  }) {
    return FirebasePartner(
      id: id,
      requesterId: requesterId,
      recipientId: recipientId ?? this.recipientId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientName: recipientName ?? this.recipientName,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      inviteToken: inviteToken ?? this.inviteToken,
      sharedGoalIds: sharedGoalIds ?? this.sharedGoalIds,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'FirebasePartner(id: $id, status: $status, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirebasePartner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// User profile model for storing user information
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isOnline;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.isOnline = false,
    this.preferences = const {},
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isOnline': isOnline,
      'preferences': preferences,
    };
  }

  // Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    DateTime? lastLoginAt,
    bool? isOnline,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? this.preferences,
    );
  }
} 