import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:latest_fyp/services/user_service.dart';
import 'providers/auth_state_provider.dart';
import 'router/app_router.dart';

// 1. Initialize Local Notifications (Global)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 2. Define the Channel (Must match AndroidManifest)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 3. Create the Channel (Critical for Android Pop-ups)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 4. Force Foreground Notifications
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      print(
        "Auth Listener: User logged in (${user.uid}). Setting up notifications...",
      );
      setupNotifications(user.uid);
    } else {
      print("Auth Listener: User is logged out.");
    }
  });

  runApp(const MyApp());
}

// --------------------------------------------------------------------------
// Notification Setup Logic
// --------------------------------------------------------------------------
Future<void> setupNotifications(String? userId) async {
  // Safety check: Don't run if no user ID provided
  if (userId == null) return;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request Permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');

    // 1. Get the current token immediately
    String? token = await messaging.getToken();

    if (token != null) {
      // Save it to Firestore using your UserService
      // (Ensure your UserService.saveUserToken uses SetOptions(merge: true))
      print('Saving FCM Token for user: $userId');
      await UserService().saveUserToken(userId, token);
    }

    // 2. Listen for future token refreshes (e.g. while app is running)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed. Updating Firestore...');
      UserService().saveUserToken(userId, newToken);
    });

    // 3. Handle Foreground Messages (Optional debugging)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');

        // Optional: Show local notification manually if needed
        /*
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: 'launch_background',
              ),
            ),
          );
        }
        */
      }
    });
  } else {
    print('User declined or has not accepted permission');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthStateProvider(),
      child: Builder(
        builder: (context) {
          final authStateProvider = Provider.of<AuthStateProvider>(
            context,
            listen: true, // Listen to changes to trigger re-builds on login
          );

          final router = createRouter(authStateProvider);

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
