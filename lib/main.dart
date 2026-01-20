import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latest_fyp/services/alarm_service.dart';
import 'package:provider/provider.dart';
import 'package:latest_fyp/services/user_service.dart';
import 'providers/auth_state_provider.dart';
import 'router/app_router.dart';
import 'package:timezone/data/latest.dart' as tz; // Add this import

// 1. Initialize Local Notifications (Global)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 2. HIGH IMPORTANCE CHANNEL (for FCM notifications)
const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

// 3. ALARM CHANNEL (for local alarm notifications) - CRITICAL!
const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
  'reminder_alarms', // MUST match AlarmService channel ID
  'Reminder Alarms',
  description: 'Alarms for medication and appointment reminders',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Firebase.initializeApp();
  print('✅ Firebase initialized');

  // Initialize alarm service FIRST
  await AlarmService().initialize();
  print('✅ AlarmService initialized');

  // 3. Create BOTH notification channels
  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidImpl != null) {
    // Create high importance channel (FCM)
    await androidImpl.createNotificationChannel(highImportanceChannel);
    print('✅ High importance channel created');

    // Create alarm channel (Local alarms) - CRITICAL!
    await androidImpl.createNotificationChannel(alarmChannel);
    print('✅ Alarm channel created');
  }

  // 4. Force Foreground Notifications
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  String? initialRoute;
  try {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        print(
          '🚀 App launched via Alarm! Redirecting to: /reminder-alarm/$payload',
        );
        initialRoute = '/reminder-alarm/$payload';
      }
    }
  } catch (e) {
    print('Error checking notification launch: $e');
  }
  // 5. Listen to auth state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      print('👤 User logged in: ${user.uid}');
      setupNotifications(user.uid);

      // Schedule all pending reminders for this user
      AlarmService().scheduleAllUserReminders(user.uid);
    } else {
      print('👤 User logged out');
    }
  });

  print('✅ App initialization complete');
  runApp(MyApp(initialRoute: initialRoute));
}

// --------------------------------------------------------------------------
// Notification Setup Logic
// --------------------------------------------------------------------------
Future<void> setupNotifications(String? userId) async {
  if (userId == null) return;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request Permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ FCM permission granted');

    // 1. Get the current token
    String? token = await messaging.getToken();

    if (token != null) {
      print('📱 FCM Token: ${token.substring(0, 20)}...');
      await UserService().saveUserToken(userId, token);
    }

    // 2. Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed');
      UserService().saveUserToken(userId, newToken);
    });

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground message received');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
    });
  } else {
    print('❌ FCM permission denied');
  }
}

class MyApp extends StatelessWidget {
  final String? initialRoute;
  MyApp({Key? key, this.initialRoute}) : super(key: key);

  // Create navigator key - CRITICAL for alarm navigation
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Set navigator key for AlarmService - CRITICAL!
    AlarmService.navigatorKey = navigatorKey;
    print('🗺️ Navigator key set for AlarmService');

    return ChangeNotifierProvider(
      create: (_) => AuthStateProvider(),
      child: Builder(
        builder: (context) {
          final authStateProvider = Provider.of<AuthStateProvider>(
            context,
            listen: true,
          );

          // PASS THE INITIAL ROUTE HERE
          final router = createRouter(
            authStateProvider,
            initialLocation: initialRoute,
          );

          return MaterialApp.router(
            title: 'Smart Elderly Care',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Roboto',
              scaffoldBackgroundColor: Colors.white,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
