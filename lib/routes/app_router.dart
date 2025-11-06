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
import '../views/caregiver_reminder_create_view.dart';
import '../views/caregiver_reminder_edit_view.dart';
import '../views/caregiver_group_list_view.dart';
import '../views/caregiver_group_detail_view.dart';
import '../views/caregiver_group_create_view.dart';
import '../views/caregiver_profile_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_selection_view.dart';
import '../views/auth/register_elderly_view.dart';
import '../views/auth/register_caregiver_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterSelectionView(),
    ),
    GoRoute(
      path: '/register/elderly',
      builder: (context, state) => const RegisterElderlyView(),
    ),
    GoRoute(
      path: '/register/caregiver',
      builder: (context, state) => const RegisterCaregiverView(),
    ),

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
      builder: (context, state) => const CaregiverReminderCreateView(),
    ),
    GoRoute(
      path: '/caregiver/reminder/edit',
      builder: (context, state) => const CaregiverReminderEditView(),
    ),
    GoRoute(
      path: '/caregiver/groups',
      builder: (context, state) => const CaregiverGroupListView(),
    ),
    GoRoute(
      path: '/caregiver/groups/detail',
      builder: (context, state) => const CaregiverGroupDetailView(),
    ),
    GoRoute(
      path: '/caregiver/groups/create',
      builder: (context, state) => const CaregiverGroupCreateView(),
    ),
    GoRoute(
      path: '/caregiver/profile',
      builder: (context, state) => const CaregiverProfileView(),
    ),
  ],
);
