import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
// import 'package:firebase_core/firebase_core.dart'; // Uncomment when Firebase is configured

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/chat_service.dart';
import 'core/services/call_service.dart';
// import 'features/notifications/services/notification_service.dart'; // Uncomment when Firebase is configured

// Providers
import 'features/auth/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';

// Call screens
import 'features/call/screens/incoming_call_screen.dart';
import 'features/call/models/call_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (uncomment when configured)
  // try {
  //   await Firebase.initializeApp();
  //   print('✅ Firebase initialized');
  // } catch (e) {
  //   print('⚠️  Firebase initialization failed: $e');
  //   print('   App will continue without push notifications');
  // }
  
  // Initialize services
  await AppConfig.initialize();
  await StorageService.initialize();
  
  // Initialize API service
  ApiService().initialize();
  
  runApp(const TutorBookingApp());
}

class TutorBookingApp extends StatefulWidget {
  const TutorBookingApp({Key? key}) : super(key: key);

  @override
  State<TutorBookingApp> createState() => _TutorBookingAppState();
}

class _TutorBookingAppState extends State<TutorBookingApp> {
  final SocketService _socketService = SocketService();
  final ChatService _chatService = ChatService();
  final CallService _callService = CallService();
  // final NotificationService _notificationService = NotificationService(); // Uncomment when Firebase is configured

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupIncomingCallListener();
    _setupNotificationListeners();
  }

  void _initializeServices() async {
    print('🚀 Initializing app services...');
    
    // Connect to socket when app starts
    print('🔌 Connecting to Socket.IO...');
    await _socketService.connect();
    
    // Wait a bit to see if connection succeeds
    await Future.delayed(const Duration(seconds: 2));
    
    if (_socketService.isConnected) {
      print('✅ Socket.IO connected successfully!');
    } else {
      print('❌ Socket.IO connection failed or still connecting...');
      print('⚠️ Real-time features may not work!');
    }
    
    // Initialize chat service
    print('💬 Initializing chat service...');
    _chatService.initialize();
    
    // Initialize call service
    print('📞 Initializing call service...');
    _callService.initialize();
    
    print('✅ All services initialized');
    
    // Initialize notification service (uncomment when Firebase is configured)
    // await _notificationService.initialize(
    //   onNotificationReceived: (notification) {
    //     print('📬 Notification received in app: ${notification.title}');
    //   },
    //   onNotificationTapped: (route) {
    //     print('👆 Notification tapped, navigating to: $route');
    //     final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    //     if (context != null && route.isNotEmpty) {
    //       // You can use GoRouter to navigate
    //       // context.go(route);
    //     }
    //   },
    // );
  }

  void _setupNotificationListeners() {
    // Listen for Socket.IO notifications
    _socketService.on('notification', (data) {
      print('🔔 Socket.IO notification: $data');
      // Show a snackbar or local notification
      final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['title'] ?? 'New Notification'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to notifications screen
              },
            ),
          ),
        );
      }
    });
  }

  void _setupIncomingCallListener() {
    // Listen for incoming calls
    _callService.incomingCallStream.listen((incomingCall) {
      // Show incoming call screen
      final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(incomingCall: incomingCall),
            fullscreenDialog: true,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Tutor Booking App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

// Global error handler
class GlobalErrorHandler extends StatelessWidget {
  final Widget child;
  
  const GlobalErrorHandler({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}