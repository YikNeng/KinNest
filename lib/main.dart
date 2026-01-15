import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Optional but recommended for custom foreground UI
import 'package:latest_fyp/services/user_service.dart';
import 'package:provider/provider.dart';
import 'providers/auth_state_provider.dart';
import 'router/app_router.dart';

// 1. Initialize Local Notifications (Add this global variable)
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

  // 4. Force Foreground Notifications (iOS/Android)
  // This makes the notification pop up even if the app is OPEN
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Check for user
  User? currentUser = FirebaseAuth.instance.currentUser;

  // Start listening for notifications
  setupNotifications(currentUser?.uid);

  runApp(const MyApp());
}

Future<void> setupNotifications(String? userId) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request Permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');

    // Get & Save Token
    String? token = await messaging.getToken();
    if (userId != null && token != null) {
      await UserService().saveUserToken(userId, token);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        UserService().saveUserToken(userId, newToken);
      });
    }

    // 5. Handle Foreground Messages (Optional debugging)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');

        // If you want to show a custom local notification:
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
                icon: 'launch_background', // or your icon name
              ),
            ),
          );
        }
        */
      }
    });
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
            listen: false,
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
