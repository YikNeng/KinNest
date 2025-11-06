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

final GoRouter appRouter = GoRouter(
  initialLocation: '/elderly/home',
  routes: [
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
    GoRoute(
      path: '/login',
      builder: (context, state) => const PlaceholderView(title: 'Login'),
    ),
  ],
);

// Temporary placeholder view for routes not yet implemented
class PlaceholderView extends StatelessWidget {
  final String title;

  const PlaceholderView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
