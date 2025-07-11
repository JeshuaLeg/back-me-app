import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import '../services/firebase_partner_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebasePartnerService _partnerService = FirebasePartnerService();
  
  StreamSubscription<PendingDynamicLinkData>? _linkSubscription;
  String? _pendingInviteToken;

  // Initialize deep linking
  Future<void> initialize() async {
    // Handle initial link when app is opened from terminated state
    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      await _handleDynamicLink(initialLink);
    }

    // Listen for incoming links when app is already running
    _linkSubscription = FirebaseDynamicLinks.instance.onLink.listen(
      (PendingDynamicLinkData dynamicLinkData) async {
        await _handleDynamicLink(dynamicLinkData);
      },
      onError: (error) {
        print('Deep link error: $error');
      },
    );
  }

  // Handle dynamic link
  Future<void> _handleDynamicLink(PendingDynamicLinkData linkData) async {
    final Uri link = linkData.link;
    print('Received dynamic link: $link');

    // Check if it's an invite link
    if (link.pathSegments.contains('invite') && link.pathSegments.length >= 2) {
      final inviteToken = link.pathSegments[link.pathSegments.indexOf('invite') + 1];
      await _handleInviteLink(inviteToken);
    }
  }

  // Handle invite link
  Future<void> _handleInviteLink(String inviteToken) async {
    print('Handling invite token: $inviteToken');

    // Check if user is authenticated
    if (_auth.currentUser == null) {
      // Store token to process after authentication
      _pendingInviteToken = inviteToken;
      print('User not authenticated, storing invite token for later');
      return;
    }

    // Process the invite immediately
    await _processInviteToken(inviteToken);
  }

  // Process invite token
  Future<bool> _processInviteToken(String inviteToken) async {
    try {
      final partnership = await _partnerService.acceptSmsInvite(inviteToken);
      if (partnership != null) {
        print('Successfully accepted SMS invite: ${partnership.id}');
        // Could show a success dialog or navigate to partners screen
        return true;
      } else {
        print('Invalid or expired invite token');
        return false;
      }
    } catch (e) {
      print('Error processing invite token: $e');
      return false;
    }
  }

  // Check for pending invite after authentication
  Future<void> checkPendingInvite() async {
    if (_pendingInviteToken != null && _auth.currentUser != null) {
      final token = _pendingInviteToken!;
      _pendingInviteToken = null;
      await _processInviteToken(token);
    }
  }

  // Create invite dynamic link
  Future<String> createInviteLink(String inviteToken) async {
    final currentUser = _auth.currentUser;
    final senderName = currentUser?.displayName ?? 'A friend';
    
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://backmeapp.page.link', // Replace with your domain
      link: Uri.parse('https://backme.app/invite/$inviteToken'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.back_me_app', // Replace with your package name
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.backMeApp', // Replace with your bundle ID
        minimumVersion: '1.0.0',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: '$senderName invited you to BackMe!',
        description: 'Join $senderName as an accountability partner on BackMe - the app that helps you achieve your goals.',
        imageUrl: Uri.parse('https://your-app-icon-url.com/icon.png'), // Replace with your app icon URL
      ),
    );

    final ShortDynamicLink shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  // Alternative method: Create a simple invite URL for SMS
  String createSimpleInviteUrl(String inviteToken) {
    return 'https://backme.app/invite/$inviteToken';
  }

  // Dispose
  void dispose() {
    _linkSubscription?.cancel();
  }

  // Get pending invite token (for checking in UI)
  String? get pendingInviteToken => _pendingInviteToken;
  
  // Clear pending invite token
  void clearPendingInviteToken() {
    _pendingInviteToken = null;
  }
} 