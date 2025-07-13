import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/firebase_goal_service.dart';
import 'services/firebase_partner_service.dart';
import 'services/firebase_achievement_service.dart';
import 'services/firebase_reminder_service.dart';
import 'services/deep_link_service.dart';
import 'services/achievement_service.dart';
import 'services/auth_service.dart';
import 'utils/smooth_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize services
  await _initializeServices();
  
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  // Initialize Achievement Service (will auto-initialize Firebase achievements)
  final achievementService = AchievementService();
  
  // Initialize Deep Link Service
  final deepLinkService = DeepLinkService();
  await deepLinkService.initialize();
  
  // Listen for auth state changes to initialize other services
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      // User is signed in, initialize user-specific services
      final goalService = FirebaseGoalService();
      final partnerService = FirebasePartnerService();
      final reminderService = FirebaseReminderService();
      
      await Future.wait([
        goalService.initialize(),
        partnerService.initialize(),
      ]);
      
      // Initialize notifications for reminders
      await reminderService.initializeNotifications();
      
      // Check for pending invites after authentication
      await deepLinkService.checkPendingInvite();
      
      // Create or update user profile
      await partnerService.createOrUpdateUserProfile(
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
      );
      
      // Sync achievement service with user data
      await achievementService.syncWithFirebase();
    } else {
      // User is signed out, dispose services if needed
      final goalService = FirebaseGoalService();
      final partnerService = FirebasePartnerService();
      
      goalService.dispose();
      partnerService.dispose();
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BackMe',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            );
          }

          // Use smooth animated switcher for auth/home transition
          return SmoothTransitions.smoothSwitcher(
            duration: const Duration(milliseconds: 400), // Slower fade in
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInQuad, // Faster fade out
            child: snapshot.hasData 
                ? const HomeScreen(key: ValueKey('home'))
                : const AuthScreen(key: ValueKey('auth')),
          );
        },
      ),
    );
  }
}

class AppTheme {
  // AA-compliant dark color palette - easier on the eyes
  static const Color primarySlate = Color(0xFF475569);      // Muted slate blue
  static const Color secondaryTeal = Color(0xFF0F766E);     // Muted teal
  static const Color accentIndigo = Color(0xFF6366F1);      // Softer indigo
  static const Color successGreen = Color(0xFF059669);      // Muted green
  static const Color warningAmber = Color(0xFFD97706);      // Muted amber
  static const Color errorRose = Color(0xFFDC2626);         // Muted red
  
  // Surface colors for better contrast
  static const Color darkSurface = Color(0xFF1E293B);       // Dark blue-gray
  static const Color darkCard = Color(0xFF334155);          // Lighter dark surface
  static const Color lightText = Color(0xFFF1F5F9);         // High contrast light text
  static const Color mutedText = Color(0xFFCBD5E1);         // Muted text
  
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySlate,
      brightness: Brightness.light,
      primary: primarySlate,
      secondary: secondaryTeal,
      tertiary: accentIndigo,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: primarySlate,
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shadowColor: primarySlate.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: primarySlate.withValues(alpha: 0.3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      elevation: 2,
      shadowColor: primarySlate.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySlate,
      brightness: Brightness.dark,
      primary: accentIndigo,           // Softer primary for dark mode
      secondary: secondaryTeal,
      tertiary: primarySlate,
      surface: darkSurface,            // Custom dark surface
      onSurface: lightText,            // High contrast text
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Very dark background
    cardColor: darkCard,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: lightText,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: lightText,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: lightText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        color: lightText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        color: mutedText,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: lightText,
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: lightText,
    ),
    cardTheme: CardThemeData(
      elevation: 6,
      color: darkCard,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        backgroundColor: accentIndigo,
        foregroundColor: lightText,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: accentIndigo,
        foregroundColor: lightText,
      ),
    ),
    chipTheme: ChipThemeData(
      elevation: 2,
      backgroundColor: darkCard,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
  
  // Updated gradient styles with AA-compliant colors
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primarySlate, secondaryTeal],
  );
  
  static LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentIndigo, primarySlate],
  );
  
  static LinearGradient get successGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, Color(0xFF10B981)],
  );
  
  static LinearGradient get warningGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningAmber, Color(0xFFF59E0B)],
  );
  
  static LinearGradient get errorGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [errorRose, Color(0xFFEF4444)],
  );
  
  // Dark mode specific gradients for better visual hierarchy
  static LinearGradient get darkPrimaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF374151), Color(0xFF4B5563)],
  );
  
  static LinearGradient get darkAccentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
  
  static LinearGradient get darkSuccessGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );
}
