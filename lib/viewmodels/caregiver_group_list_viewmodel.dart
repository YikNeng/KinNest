// lib/viewmodels/caregiver_group_list_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/group_model.dart';

class CaregiverGroupListViewModel extends ChangeNotifier {
  List<GroupModel> _groups = [];
  bool _isLoading = false;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;

  CaregiverGroupListViewModel() {
    _loadDummyGroups();
  }

  void _loadDummyGroups() {
    _isLoading = true;
    notifyListeners();

    // TODO: Replace with actual API call to fetch groups
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _groups = [
        GroupModel(
          id: '1',
          groupName: 'Family Care Group',
          numberOfElderly: 3,
          numberOfCaregivers: 2,
          totalUpcomingReminders: 12,
        ),
      ];

      _isLoading = false;
      notifyListeners();
    });
  }

  void refreshGroups() {
    // TODO: Implement refresh logic to fetch updated data from backend
    _loadDummyGroups();
  }
}
