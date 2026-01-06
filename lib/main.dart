import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_state_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provide AuthStateProvider to entire app
    return ChangeNotifierProvider(
      create: (_) => AuthStateProvider(),
      child: Builder(
        builder: (context) {
          // Get AuthStateProvider instance
          final authStateProvider = Provider.of<AuthStateProvider>(
            context,
            listen: false,
          );

          // Create router with auth state provider
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
