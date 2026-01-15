import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:latest_fyp/views/caregiver/caregiver_home_page.dart';
import 'package:latest_fyp/views/caregiver/create_group_page.dart';
import 'package:latest_fyp/views/caregiver/group_detail_page.dart';
import 'package:latest_fyp/views/caregiver/group_settings_page.dart';
import 'package:latest_fyp/views/caregiver/invite_member_page.dart';
import 'package:latest_fyp/views/elderly/invitation_list_page.dart';
import 'package:latest_fyp/views/reminders/create_edit_reminder_page.dart';
import 'package:latest_fyp/views/reminders/reminder_list_page.dart';
import '../providers/auth_state_provider.dart';
import '../services/user_service.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/loading_view.dart';

// Import bottom nav scaffolds
import '../views/elderly/elderly_bottom_nav_scaffold.dart';
import '../views/caregiver/caregiver_bottom_nav_scaffold.dart';

// Import elderly pages
import '../views/elderly/elderly_home_page.dart';
import '../views/elderly/elderly_reminders_page.dart';
import '../views/elderly/elderly_exercise_page.dart';
import '../views/elderly/elderly_music_page.dart';
import '../views/elderly/elderly_profile_page.dart';
import '../views/elderly/elderly_exercise_routine_page.dart';

// Import caregiver pages
import '../views/caregiver/caregiver_groups_page.dart';
import '../views/caregiver/caregiver_profile_page.dart';

// Import ViewModels
import '../viewmodels/exercise_viewmodel.dart';

/// Creates GoRouter instance with auth-based and role-based redirects
GoRouter createRouter(AuthStateProvider authStateProvider) {
  final UserService userService = UserService();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authStateProvider,

    // Global redirect logic
    redirect: (BuildContext context, GoRouterState state) async {
      final bool isAuthenticated = authStateProvider.isAuthenticated;
      final bool isInitialized = authStateProvider.isInitialized;
      final String currentPath = state.uri.path;

      // Show loading while Firebase Auth initializes
      if (!isInitialized) {
        return '/loading';
      }

      // If user is NOT authenticated
      if (!isAuthenticated) {
        if (currentPath == '/login' || currentPath == '/register') {
          return null;
        }
        return '/login';
      }

      // If user IS authenticated
      if (isAuthenticated) {
        final String? userId = authStateProvider.userId;

        // Prevent access to login/register if already logged in
        if (currentPath == '/login' || currentPath == '/register') {
          try {
            final userProfile = await userService.getUserProfile(userId!);
            if (userProfile != null) {
              final String role = userProfile['role'] as String;

              // Redirect to appropriate home
              if (role == 'elderly') {
                return '/elderly/home';
              } else if (role == 'caregiver') {
                return '/caregiver/home';
              }
            }
          } catch (e) {
            debugPrint('Error fetching user role: $e');
            return null;
          }
        }

        // Verify user is accessing correct role pages
        if (currentPath.startsWith('/elderly/')) {
          try {
            final userProfile = await userService.getUserProfile(userId!);
            if (userProfile != null) {
              final String role = userProfile['role'] as String;
              if (role != 'elderly') {
                return '/caregiver/groups';
              }
            }
          } catch (e) {
            debugPrint('Error verifying user role: $e');
          }
        }

        if (currentPath.startsWith('/caregiver/')) {
          try {
            final userProfile = await userService.getUserProfile(userId!);
            if (userProfile != null) {
              final String role = userProfile['role'] as String;
              if (role != 'caregiver') {
                return '/elderly/home';
              }
            }
          } catch (e) {
            debugPrint('Error verifying user role: $e');
          }
        }
      }

      return null;
    },

    routes: [
      // Loading screen
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingView(),
      ),

      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),

      // Elderly routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ExerciseViewModel()),
            ],
            child: ElderlyBottomNavScaffold(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/elderly/home',
            builder: (context, state) => const ElderlyHomePage(),
          ),
          GoRoute(
            path: '/elderly/reminders',
            builder: (context, state) => const ReminderListPage(),
          ),
          GoRoute(
            path: '/elderly/exercise',
            builder: (context, state) {
              final skipAuto = state.uri.queryParameters['skipAuto'] == 'true';
              return ElderlyExercisePage(skipAutoNavigate: skipAuto);
            },
          ),
          GoRoute(
            path: '/elderly/music',
            builder: (context, state) => const ElderlyMusicPage(),
          ),
          GoRoute(
            path: '/elderly/profile',
            builder: (context, state) => const ElderlyProfilePage(),
          ),
        ],
      ),

      GoRoute(
        path: '/elderly/exercise/result',
        builder: (context, state) {
          return const ElderlyExerciseRoutinePage();
        },
      ),

      // NEW: Elderly reminder management routes (outside bottom nav)
      GoRoute(
        path: '/elderly/groups/:groupId/reminders/create',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return CreateEditReminderPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/elderly/groups/:groupId/reminders/:reminderId/edit',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final reminderId = state.pathParameters['reminderId']!;
          return CreateEditReminderPage(
            groupId: groupId,
            reminderId: reminderId,
          );
        },
      ),

      // Caregiver routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return CaregiverBottomNavScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/caregiver/home',
            builder: (context, state) => const CaregiverHomePage(),
          ),
          GoRoute(
            path: '/caregiver/reminders',
            builder: (context, state) => const ReminderListPage(),
          ),
          GoRoute(
            path: '/caregiver/groups',
            builder: (context, state) => const CaregiverGroupsPage(),
          ),
          GoRoute(
            path: '/caregiver/profile',
            builder: (context, state) => const CaregiverProfilePage(),
          ),
        ],
      ),

      // Caregiver group routes (outside bottom nav)
      GoRoute(
        path: '/caregiver/groups/create',
        builder: (context, state) => const CreateGroupPage(),
      ),
      GoRoute(
        path: '/caregiver/groups/:groupId/invite',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return InviteMemberPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/caregiver/groups/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupDetailPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/caregiver/groups/:groupId/reminders/create',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return CreateEditReminderPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/caregiver/groups/:groupId/reminders/:reminderId/edit',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final reminderId = state.pathParameters['reminderId']!;
          return CreateEditReminderPage(
            groupId: groupId,
            reminderId: reminderId,
          );
        },
      ),
      GoRoute(
        path: '/caregiver/groups/:groupId/settings',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupSettingsPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/caregiver/groups/:groupId/members',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Members')),
            body: Center(
              child: Text(
                'Member Management Page\nGroup ID: $groupId\n\nComing Soon',
              ),
            ),
          );
        },
      ),

      // Elderly invitation routes
      GoRoute(
        path: '/elderly/invitations',
        builder: (context, state) => const InvitationListPage(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: TextStyle(fontSize: 24, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.path,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    ),
  );
}
