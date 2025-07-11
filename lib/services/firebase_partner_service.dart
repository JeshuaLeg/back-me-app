import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:contacts_service/contacts_service.dart';  // Temporarily disabled
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/firebase_partner.dart';

class FirebasePartnerService {
  static final FirebasePartnerService _instance = FirebasePartnerService._internal();
  factory FirebasePartnerService() => _instance;
  FirebasePartnerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Collection references
  CollectionReference get _partnersCollection => _firestore.collection('partnerships');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Stream controllers for real-time updates
  final StreamController<List<FirebasePartner>> _partnersController = 
      StreamController<List<FirebasePartner>>.broadcast();
  
  Stream<List<FirebasePartner>> get partnersStream => _partnersController.stream;
  
  // Cache for partnerships
  List<FirebasePartner> _cachedPartners = [];
  StreamSubscription<QuerySnapshot>? _partnersSubscription;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Initialize service and start listening to partnerships
  Future<void> initialize() async {
    if (currentUserId != null) {
      await _startListeningToPartnerships();
    }
  }

  // Start listening to user's partnerships
  Future<void> _startListeningToPartnerships() async {
    if (currentUserId == null) return;

    _partnersSubscription?.cancel();
    _partnersSubscription = _partnersCollection
        .where('requesterId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      _updateCachedPartners(snapshot);
    });

    // Also listen to partnerships where user is the recipient
    _partnersCollection
        .where('recipientId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      _updateCachedPartners(snapshot);
    });
  }

  void _updateCachedPartners(QuerySnapshot snapshot) {
    // Merge with existing cache to avoid duplicates
    final newPartners = snapshot.docs
        .map((doc) => FirebasePartner.fromFirestore(doc))
        .toList();
    
    // Update cache
    for (final partner in newPartners) {
      final existingIndex = _cachedPartners.indexWhere((p) => p.id == partner.id);
      if (existingIndex >= 0) {
        _cachedPartners[existingIndex] = partner;
      } else {
        _cachedPartners.add(partner);
      }
    }
    
    _partnersController.add(_cachedPartners);
  }

  // Stop listening to partnerships
  void dispose() {
    _partnersSubscription?.cancel();
    _partnersController.close();
  }

  // Create or update user profile
  Future<UserProfile> createOrUpdateUserProfile({
    required String email,
    required String displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final userDoc = _usersCollection.doc(currentUserId);
    final existingDoc = await userDoc.get();

    UserProfile profile;
    
    if (existingDoc.exists) {
      // Update existing profile
      final existingProfile = UserProfile.fromFirestore(existingDoc);
      profile = existingProfile.copyWith(
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        lastLoginAt: now,
        isOnline: true,
      );
    } else {
      // Create new profile
      profile = UserProfile(
        id: currentUserId!,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        createdAt: now,
        lastLoginAt: now,
        isOnline: true,
      );
    }

    await userDoc.set(profile.toFirestore(), SetOptions(merge: true));
    return profile;
  }

  // Get user contacts
  // Future<List<Contact>> getUserContacts() async {
  //   final permission = await Permission.contacts.request();
  //   if (permission != PermissionStatus.granted) {
  //     throw Exception('Contacts permission denied');
  //   }
  //   
  //   final contacts = await ContactsService.getContacts(withThumbnails: false);
  //   return contacts.where((contact) =>
  //     contact.phones != null && contact.phones!.isNotEmpty
  //   ).toList();
  // }

  // Search for users by email or phone
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final emailQuery = _usersCollection
        .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('email', isLessThan: '${query.toLowerCase()}z')
        .limit(10);

    final emailSnapshot = await emailQuery.get();
    final users = emailSnapshot.docs
        .map((doc) => UserProfile.fromFirestore(doc))
        .where((user) => user.id != currentUserId) // Exclude self
        .toList();

    return users;
  }

  // Find existing users from contacts  
  // Future<List<UserProfile>> findUsersFromContacts(List<Contact> contacts) async {
  //   if (contacts.isEmpty) return [];
  //   
  //   // Extract emails and phone numbers from contacts
  //   final Set<String> emails = {};
  //   final Set<String> phones = {};
  //   
  //   for (final contact in contacts) {
  //     if (contact.emails != null) {
  //       emails.addAll(contact.emails!.map((e) => e.value!.toLowerCase()));
  //     }
  //     if (contact.phones != null) {
  //       phones.addAll(contact.phones!.map((p) => p.value!));
  //     }
  //   }
  //   
  //   return [];
  // }

  // Helper to batch lists into smaller chunks
  List<List<T>> _batchList<T>(List<T> list, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < list.length; i += batchSize) {
      batches.add(list.sublist(i, math.min(i + batchSize, list.length)));
    }
    return batches;
  }

  // Send partner request to existing user
  Future<FirebasePartner> sendPartnerRequest(String recipientId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if partnership already exists
    final existingPartnership = await _checkExistingPartnership(recipientId);
    if (existingPartnership != null) {
      throw Exception('Partnership already exists');
    }

    final docRef = _partnersCollection.doc();
    final partnership = FirebasePartner(
      id: docRef.id,
      requesterId: currentUserId!,
      recipientId: recipientId,
      type: InvitationType.appUser,
      createdAt: DateTime.now(),
    );

    await docRef.set(partnership.toFirestore());
    return partnership;
  }

  // Send SMS invitation
  Future<FirebasePartner> sendSmsInvitation({
    required String phoneNumber,
    required String contactName,
    String? email,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final inviteToken = _uuid.v4();
    final docRef = _partnersCollection.doc();
    
    final partnership = FirebasePartner(
      id: docRef.id,
      requesterId: currentUserId!,
      recipientPhone: phoneNumber,
      recipientName: contactName,
      recipientEmail: email,
      type: InvitationType.smsInvite,
      inviteToken: inviteToken,
      createdAt: DateTime.now(),
    );

    await docRef.set(partnership.toFirestore());

    // Send SMS
    await _sendInviteSms(phoneNumber, contactName, inviteToken);
    
    return partnership;
  }

  // Send invite SMS
  Future<void> _sendInviteSms(String phoneNumber, String contactName, String inviteToken) async {
    final currentUser = _auth.currentUser;
    final senderName = currentUser?.displayName ?? 'A friend';
    
    final message = Uri.encodeComponent(
      '$senderName invited you to be their accountability partner on BackMe! '
      'Download the app and use this link to connect: '
      'https://backme.app/invite/$inviteToken'
    );
    
    final smsUrl = 'sms:$phoneNumber?body=$message';
    
    if (await canLaunchUrl(Uri.parse(smsUrl))) {
      await launchUrl(Uri.parse(smsUrl));
    } else {
      throw Exception('Could not launch SMS app');
    }
  }

  // Accept partner request
  Future<void> acceptPartnerRequest(String partnershipId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _partnersCollection.doc(partnershipId).update({
      'status': PartnershipStatus.accepted.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Decline partner request
  Future<void> declinePartnerRequest(String partnershipId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _partnersCollection.doc(partnershipId).update({
      'status': PartnershipStatus.declined.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Accept SMS invite (when new user signs up with invite token)
  Future<FirebasePartner?> acceptSmsInvite(String inviteToken) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _partnersCollection
        .where('inviteToken', isEqualTo: inviteToken)
        .where('type', isEqualTo: InvitationType.smsInvite.name)
        .where('status', isEqualTo: PartnershipStatus.pending.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null; // Invalid or expired token
    }

    final partnershipDoc = snapshot.docs.first;
    final partnership = FirebasePartner.fromFirestore(partnershipDoc);

    // Update partnership with recipient ID
    final updatedPartnership = partnership.copyWith(
      recipientId: currentUserId,
      status: PartnershipStatus.accepted,
      respondedAt: DateTime.now(),
    );

    await _partnersCollection.doc(partnership.id).update(updatedPartnership.toFirestore());
    return updatedPartnership;
  }

  // Check if partnership already exists
  Future<FirebasePartner?> _checkExistingPartnership(String otherUserId) async {
    if (currentUserId == null) return null;

    // Check if current user sent request to other user
    final sentRequest = await _partnersCollection
        .where('requesterId', isEqualTo: currentUserId)
        .where('recipientId', isEqualTo: otherUserId)
        .limit(1)
        .get();

    if (sentRequest.docs.isNotEmpty) {
      return FirebasePartner.fromFirestore(sentRequest.docs.first);
    }

    // Check if other user sent request to current user
    final receivedRequest = await _partnersCollection
        .where('requesterId', isEqualTo: otherUserId)
        .where('recipientId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (receivedRequest.docs.isNotEmpty) {
      return FirebasePartner.fromFirestore(receivedRequest.docs.first);
    }

    return null;
  }

  // Remove partnership
  Future<void> removePartnership(String partnershipId) async {
    await _partnersCollection.doc(partnershipId).delete();
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  // Getters for filtered lists (from cached data)
  List<FirebasePartner> get partnerships => List.unmodifiable(_cachedPartners);

  List<FirebasePartner> get activePartnerships => _cachedPartners
      .where((p) => p.status == PartnershipStatus.accepted)
      .toList();

  List<FirebasePartner> get pendingRequests => _cachedPartners
      .where((p) => p.status == PartnershipStatus.pending && p.recipientId == currentUserId)
      .toList();

  List<FirebasePartner> get sentRequests => _cachedPartners
      .where((p) => p.status == PartnershipStatus.pending && p.requesterId == currentUserId)
      .toList();

  List<FirebasePartner> get smsInvites => _cachedPartners
      .where((p) => p.type == InvitationType.smsInvite && p.requesterId == currentUserId)
      .toList();

  // Get partner IDs for active partnerships
  List<String> get activePartnerIds {
    return activePartnerships
        .map((p) => p.getPartnerId(currentUserId!))
        .where((id) => id.isNotEmpty)
        .toList();
  }
} 