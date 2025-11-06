import 'package:flutter/material.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const KinNestApp());
}

class KinNestApp extends StatelessWidget {
  const KinNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KinNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
