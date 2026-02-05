import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/user_model.dart';

// Screens we have
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/tutor_search_screen.dart';
import '../../features/student/screens/student_bookings_screen.dart';
import '../../features/student/screens/student_profile_screen.dart';
import '../../features/student/screens/student_messages_screen.dart';
import '../../features/student/screens/tutor_detail_screen.dart';
import '../../features/tutor/screens/tutor_dashboard_screen.dart';
import '../../features/tutor/screens/tutor_schedule_screen.dart';
import '../../features/tutor/screens/tutor_bookings_screen.dart';
import '../../features/tutor/screens/tutor_profile_screen.dart';
import '../../features/tutor/screens/tutor_earnings_screen.dart';
import '../../features/tutor/screens/create_tutor_profile_screen.dart';
import '../../features/tutor/screens/tutor_messages_screen.dart' show TutorMessagesScreen;
import '../../features/student/screens/tutor_booking_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/student/screens/create_review_screen.dart';
import '../../features/student/screens/tutor_reviews_screen.dart';
import '../../features/student/screens/my_reviews_screen.dart';
import '../../features/tutor/screens/tutor_reviews_management_screen.dart';
import '../../features/student/screens/student_notifications_screen.dart';
import '../../features/tutor/screens/tutor_notifications_screen.dart';
import '../../features/tutor/screens/notification_preferences_screen.dart';
import '../../features/support/screens/help_support_screen.dart';
import '../../features/support/screens/create_ticket_screen.dart';
import '../../features/support/screens/my_tickets_screen.dart';
import '../../features/support/screens/ticket_detail_screen.dart';
import '../../features/support/screens/faq_screen.dart';
import '../../features/session/screens/active_session_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: _redirect,
    refreshListenable: AuthRouterNotifier(),
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Dashboard Routes
      GoRoute(
        path: '/student-dashboard',
        name: 'student-dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/tutor-dashboard',
        name: 'tutor-dashboard',
        builder: (context, state) => const TutorDashboardScreen(),
      ),
      GoRoute(
        path: '/create-tutor-profile',
        name: 'create-tutor-profile',
        builder: (context, state) => const CreateTutorProfileScreen(),
      ),

      // Student Routes
      GoRoute(
        path: '/tutor-search',
        name: 'tutor-search',
        builder: (context, state) => const TutorSearchScreen(),
      ),
      GoRoute(
        path: '/student-bookings',
        name: 'student-bookings',
        builder: (context, state) => const StudentBookingsScreen(),
      ),
      GoRoute(
        path: '/student-profile',
        name: 'student-profile',
        builder: (context, state) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: '/student-messages',
        name: 'student-messages',
        builder: (context, state) => const StudentMessagesScreen(),
      ),
      GoRoute(
        path: '/tutor-detail/:tutorId',
        name: 'tutor-detail',
        builder: (context, state) {
          final tutorId = state.pathParameters['tutorId']!;
          return TutorDetailScreen(tutorId: tutorId);
        },
      ),
      GoRoute(
        path: '/student/book-tutor',
        name: 'book-tutor',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TutorBookingScreen(
            tutorId: extra['tutorId'],
            tutorName: extra['tutorName'],
            subject: extra['subject'],
            subjectId: extra['subjectId'] ?? '',
            hourlyRate: extra['hourlyRate'],
          );
        },
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChatScreen(
            conversationId: extra['conversationId'],
            participantId: extra['participantId'],
            participantName: extra['participantName'],
            participantAvatar: extra['participantAvatar'],
            subject: extra['subject'],
          );
        },
      ),

      // Review Routes
      GoRoute(
        path: '/create-review/:bookingId',
        name: 'create-review',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return CreateReviewScreen(
            bookingId: bookingId,
            bookingDetails: extra?['bookingDetails'],
          );
        },
      ),
      GoRoute(
        path: '/tutor-reviews/:tutorId',
        name: 'view-tutor-reviews',
        builder: (context, state) {
          final tutorId = state.pathParameters['tutorId']!;
          final tutorName = state.uri.queryParameters['tutorName'] ?? 'Tutor';
          return TutorReviewsScreen(
            tutorId: tutorId,
            tutorName: tutorName,
          );
        },
      ),
      GoRoute(
        path: '/my-reviews',
        name: 'my-reviews',
        builder: (context, state) => const MyReviewsScreen(),
      ),

      // Tutor Routes
      GoRoute(
        path: '/tutor-schedule',
        name: 'tutor-schedule',
        builder: (context, state) => const TutorScheduleScreen(),
      ),
      GoRoute(
        path: '/tutor-bookings',
        name: 'tutor-bookings',
        builder: (context, state) => const TutorBookingsScreen(),
      ),
      GoRoute(
        path: '/tutor-profile',
        name: 'tutor-profile',
        builder: (context, state) => const TutorProfileScreen(),
      ),
      GoRoute(
        path: '/tutor-earnings',
        name: 'tutor-earnings',
        builder: (context, state) => const TutorEarningsScreen(),
      ),
      GoRoute(
        path: '/tutor-messages',
        name: 'tutor-messages',
        builder: (context, state) => TutorMessagesScreen(),
      ),
      GoRoute(
        path: '/tutor-reviews',
        name: 'tutor-reviews',
        builder: (context, state) => const TutorReviewsManagementScreen(),
      ),
      
      // Session Route
      GoRoute(
        path: '/active-session/:bookingId',
        name: 'active-session',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          final sessionData = state.extra as Map<String, dynamic>;
          return ActiveSessionScreen(
            bookingId: bookingId,
            sessionData: sessionData,
          );
        },
      ),
      
      // Notifications Routes
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const StudentNotificationsScreen(),
      ),
      
      GoRoute(
        path: '/tutor-notifications',
        name: 'tutor-notifications',
        builder: (context, state) => const TutorNotificationsScreen(),
      ),
      
      GoRoute(
        path: '/notification-preferences',
        name: 'notification-preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      
      // Support Routes
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/support/create-ticket',
        name: 'create-ticket',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/support/tickets',
        name: 'my-tickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/support/tickets/:ticketId',
        name: 'ticket-detail',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          return TicketDetailScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/support/faqs',
        name: 'faqs',
        builder: (context, state) => const FAQScreen(),
      ),
    ],
  );

  // Route redirect logic
  static String? _redirect(BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;
    final requiresEmailVerification = authProvider.requiresEmailVerification;
    final requiresProfileCompletion = authProvider.requiresProfileCompletion;

    final isOnSplash = state.matchedLocation == '/splash';
    final isOnOnboarding = state.matchedLocation == '/onboarding';
    final isOnAuth = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register') ||
        state.matchedLocation.startsWith('/verify-email') ||
        state.matchedLocation.startsWith('/forgot-password');
    final isOnProfileCreation = state.matchedLocation.startsWith('/create-tutor-profile');

    // Debug logging
    print('🔄 Router redirect check:');
    print('  Current location: ${state.matchedLocation}');
    print('  isAuthenticated: $isAuthenticated');
    print('  user role: ${user?.role}');
    print('  requiresEmailVerification: $requiresEmailVerification');
    print('  requiresProfileCompletion: $requiresProfileCompletion');
    print('  profileCompleted: ${user?.profileCompleted}');

    // Show splash screen initially
    if (isOnSplash) {
      print('🔄 Staying on splash screen');
      return null;
    }

    // If not authenticated, redirect to auth screens
    if (!isAuthenticated) {
      print('🔄 User not authenticated');
      if (requiresEmailVerification) {
        final email = authProvider.user?.email ?? '';
        print('🔄 Redirecting to email verification');
        return '/verify-email?email=${Uri.encodeComponent(email)}';
      }
      if (isOnAuth || isOnOnboarding) {
        print('🔄 Already on auth screen, staying');
        return null;
      }
      print('🔄 Redirecting to login');
      return '/login';
    }

    // If authenticated but requires email verification
    if (requiresEmailVerification && !state.matchedLocation.startsWith('/verify-email')) {
      final email = authProvider.user?.email ?? '';
      print('🔄 Redirecting to email verification (authenticated user)');
      return '/verify-email?email=${Uri.encodeComponent(email)}';
    }

    // If authenticated but requires profile completion
    if (requiresProfileCompletion && !isOnProfileCreation) {
      if (user?.role == UserRole.tutor) {
        print('🔄 Redirecting tutor to profile creation');
        return '/create-tutor-profile';
      }
      // For students, allow navigation to other screens but redirect from auth screens
      if (isOnAuth || isOnOnboarding) {
        print('🔄 Redirecting student to dashboard from auth screens');
        return '/student-dashboard';
      }
      // Allow students to navigate to other screens even with incomplete profile
    }

    // If authenticated and on auth screens, redirect to appropriate dashboard
    if (isOnAuth || isOnOnboarding) {
      if (user?.role == UserRole.student) {
        print('🔄 Redirecting authenticated student to dashboard');
        return '/student-dashboard';
      } else if (user?.role == UserRole.tutor) {
        print('🔄 Redirecting authenticated tutor to dashboard');
        return '/tutor-dashboard';
      }
    }

    print('🔄 No redirect needed');
    return null;
  }
}

// Placeholder screen for routes we haven't implemented yet
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen is under construction',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}