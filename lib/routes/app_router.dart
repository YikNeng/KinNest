// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/elderly_home_view.dart';
import '../views/elderly_reminder_list_view.dart';
import '../views/elderly_reminder_detail_view.dart';
import '../views/elderly_reminder_edit_view.dart';
import '../views/elderly_reminder_create_view.dart';
import '../views/elderly_music_view.dart';
import '../views/elderly_exercise_view.dart';
import '../views/elderly_exercise_plan_view.dart';
import '../views/elderly_profile_view.dart';
import '../views/caregiver_home_view.dart';
import '../views/caregiver_reminder_list_view.dart';
import '../views/caregiver_reminder_detail_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation:
      '/caregiver/home', // Change to '/elderly/home' for elderly view
  routes: [
    // Elderly routes
    GoRoute(
      path: '/elderly/home',
      builder: (context, state) => const ElderlyHomeView(),
    ),
    GoRoute(
      path: '/elderly/reminder',
      builder: (context, state) => const ElderlyReminderListView(),
    ),
    GoRoute(
      path: '/elderly/reminder/detail',
      builder: (context, state) => const ElderlyReminderDetailView(),
    ),
    GoRoute(
      path: '/elderly/reminder/edit',
      builder: (context, state) => const ElderlyReminderEditView(),
    ),
    GoRoute(
      path: '/elderly/reminder/create',
      builder: (context, state) => const ElderlyReminderCreateView(),
    ),
    GoRoute(
      path: '/elderly/music',
      builder: (context, state) => const ElderlyMusicView(),
    ),
    GoRoute(
      path: '/elderly/exercise',
      builder: (context, state) => const ElderlyExerciseView(),
    ),
    GoRoute(
      path: '/elderly/exercise/plan',
      builder: (context, state) => const ElderlyExercisePlanView(),
    ),
    GoRoute(
      path: '/elderly/profile',
      builder: (context, state) => const ElderlyProfileView(),
    ),

    // Caregiver routes
    GoRoute(
      path: '/caregiver/home',
      builder: (context, state) => const CaregiverHomeView(),
    ),
    GoRoute(
      path: '/caregiver/reminder',
      builder: (context, state) => const CaregiverReminderListView(),
    ),
    GoRoute(
      path: '/caregiver/reminder/detail',
      builder: (context, state) => const CaregiverReminderDetailView(),
    ),
    GoRoute(
      path: '/caregiver/reminder/create',
      builder: (context, state) => const PlaceholderView(
        title: 'Create Reminder',
        backRoute: '/caregiver/reminder',
      ),
    ),
    GoRoute(
      path: '/caregiver/groups',
      builder: (context, state) => const PlaceholderView(
        title: 'Groups',
        backRoute: '/caregiver/home',
      ),
    ),
    GoRoute(
      path: '/caregiver/profile',
      builder: (context, state) => const PlaceholderView(
        title: 'Caregiver Profile',
        backRoute: '/caregiver/home',
      ),
    ),

    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const PlaceholderView(
        title: 'Login',
        backRoute: '/caregiver/home',
      ),
    ),
  ],
);

// Temporary placeholder view for routes not yet implemented
class PlaceholderView extends StatelessWidget {
  final String title;
  final String backRoute;

  const PlaceholderView({
    super.key,
    required this.title,
    required this.backRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(backRoute),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$title Page',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
