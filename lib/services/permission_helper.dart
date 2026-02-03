import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Call this after user logs in to ensure alarm permissions
Future<void> requestAlarmPermissions(BuildContext context) async {
  // Request notification permission
  var notificationStatus = await Permission.notification.request();

  // Request exact alarm permission
  var alarmStatus = await Permission.scheduleExactAlarm.request();

  if (notificationStatus.isDenied || alarmStatus.isDenied) {
    // Show dialog explaining why permissions are needed
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs notification and alarm permissions to remind you about medications and appointments.\n\n'
            'Please enable these permissions in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }
}
