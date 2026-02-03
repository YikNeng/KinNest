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
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Initialize Local Notifications (Global)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// HIGH IMPORTANCE CHANNEL (for FCM notifications)
const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

// ALARM CHANNEL (for local alarm notifications)
const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
  'reminder_alarms_v3',
  'Reminder Alarms',
  description: 'Alarms for medication and appointment reminders',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('alarm_sound'),
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

void main() async {
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Firebase.initializeApp();

  // Initialize alarm service
  await AlarmService().initialize();

  // Create BOTH notification channels
  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidImpl != null) {
    await androidImpl.createNotificationChannel(highImportanceChannel);
    await androidImpl.createNotificationChannel(alarmChannel);
  }

  // Force Foreground Notifications
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Check if launched by notification
  String? initialRoute;
  try {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        initialRoute = '/reminder-alarm/$payload';
      }
    }
  } catch (e) {
    print('Error checking notification launch: $e');
  }

  // Listen to auth state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      setupNotifications(user.uid);
      AlarmService().scheduleAllUserReminders(user.uid);
    }
  });

  // Use the StatefulWidget wrapper
  runApp(MyApp(initialRoute: initialRoute));
}

// Notification Setup Logic
Future<void> setupNotifications(String? userId) async {
  if (userId == null) return;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    if (token != null) {
      await UserService().saveUserToken(userId, token);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      UserService().saveUserToken(userId, newToken);
    });
  }
}

// Main App Widget
class MyApp extends StatefulWidget {
  final String? initialRoute;
  const MyApp({Key? key, this.initialRoute}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AlarmService.navigatorKey = navigatorKey;
  }

  @override
  Widget build(BuildContext context) {
    AlarmService.navigatorKey = navigatorKey;

    return ChangeNotifierProvider(
      create: (_) => AuthStateProvider(),
      child: Builder(
        builder: (context) {
          final authStateProvider = Provider.of<AuthStateProvider>(
            context,
            listen: false,
          );

          // Create Router with Navigator Key
          final router = createRouter(
            authStateProvider,
            initialLocation: widget.initialRoute,
            navigatorKey: navigatorKey, // PASS IT HERE
          );

          // Check queue after frame builds
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AlarmService().processPendingNavigation();
          });

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
