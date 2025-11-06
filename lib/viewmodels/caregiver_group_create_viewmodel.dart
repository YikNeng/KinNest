// lib/viewmodels/caregiver_group_create_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';

class CaregiverGroupCreateViewModel extends ChangeNotifier {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController elderlySearchController = TextEditingController();
  final TextEditingController caregiverSearchController =
      TextEditingController();

  List<UserModel> _selectedElderly = [];
  List<UserModel> _selectedCaregivers = [];
  List<UserModel> _elderlySearchResults = [];
  List<UserModel> _caregiverSearchResults = [];

  String? _groupNameError;

  List<UserModel> get selectedElderly => _selectedElderly;
  List<UserModel> get selectedCaregivers => _selectedCaregivers;
  List<UserModel> get elderlySearchResults => _elderlySearchResults;
  List<UserModel> get caregiverSearchResults => _caregiverSearchResults;
  String? get groupNameError => _groupNameError;

  CaregiverGroupCreateViewModel() {
    _loadDummySearchResults();
  }

  void _loadDummySearchResults() {
    // TODO: Replace with actual API search
    _elderlySearchResults = [
      UserModel(
        id: 'elderly_1',
        username: 'Mrs. Lim',
        email: 'mrlee@email.com',
        hashedPassword: 'hashed',
        age: 72,
        heightCm: 168.0,
        weightKg: 65.0,
        chronicDisease: true,
        chronicDiseaseNotes: 'Hypertension',
        role: UserRole.elderly,
      ),
      UserModel(
        id: 'elderly_2',
        username: 'Mrs. Chan',
        email: 'mrschan@email.com',
        hashedPassword: 'hashed',
        age: 68,
        heightCm: 155.0,
        weightKg: 58.0,
        chronicDisease: true,
        chronicDiseaseNotes: 'Diabetes',
        role: UserRole.elderly,
      ),
      UserModel(
        id: 'elderly_3',
        username: 'Uncle Tan',
        email: 'uncletan@email.com',
        hashedPassword: 'hashed',
        age: 75,
        heightCm: 170.0,
        weightKg: 70.0,
        chronicDisease: false,
        chronicDiseaseNotes: '',
        role: UserRole.elderly,
      ),
      UserModel(
        id: 'elderly_4',
        username: 'Aunty Lim',
        email: 'auntylim@email.com',
        hashedPassword: 'hashed',
        age: 70,
        heightCm: 160.0,
        weightKg: 62.0,
        chronicDisease: false,
        chronicDiseaseNotes: '',
        role: UserRole.elderly,
      ),
    ];

    _caregiverSearchResults = [
      UserModel(
        id: 'caregiver_1',
        username: 'Sarah Wong',
        email: 'sarah@email.com',
        hashedPassword: 'hashed',
        age: 35,
        heightCm: 165.0,
        weightKg: 60.0,
        chronicDisease: false,
        chronicDiseaseNotes: '',
        role: UserRole.caregiver,
      ),
      UserModel(
        id: 'caregiver_2',
        username: 'David Lim',
        email: 'david@email.com',
        hashedPassword: 'hashed',
        age: 42,
        heightCm: 175.0,
        weightKg: 75.0,
        chronicDisease: false,
        chronicDiseaseNotes: '',
        role: UserRole.caregiver,
      ),
      UserModel(
        id: 'caregiver_3',
        username: 'Emily Chen',
        email: 'emily@email.com',
        hashedPassword: 'hashed',
        age: 38,
        heightCm: 162.0,
        weightKg: 55.0,
        chronicDisease: false,
        chronicDiseaseNotes: '',
        role: UserRole.caregiver,
      ),
    ];
  }

  void addElderly(UserModel elderly) {
    if (!_selectedElderly.any((e) => e.id == elderly.id)) {
      _selectedElderly.add(elderly);
      notifyListeners();
    }
  }

  void removeElderly(String elderlyId) {
    _selectedElderly.removeWhere((e) => e.id == elderlyId);
    notifyListeners();
  }

  void addCaregiver(UserModel caregiver) {
    if (!_selectedCaregivers.any((c) => c.id == caregiver.id)) {
      _selectedCaregivers.add(caregiver);
      notifyListeners();
    }
  }

  void removeCaregiver(String caregiverId) {
    _selectedCaregivers.removeWhere((c) => c.id == caregiverId);
    notifyListeners();
  }

  bool isElderlySelected(String elderlyId) {
    return _selectedElderly.any((e) => e.id == elderlyId);
  }

  bool isCaregiverSelected(String caregiverId) {
    return _selectedCaregivers.any((c) => c.id == caregiverId);
  }

  bool validateForm() {
    bool isValid = true;

    if (groupNameController.text.trim().isEmpty) {
      _groupNameError = 'Group name is required';
      isValid = false;
    } else {
      _groupNameError = null;
    }

    notifyListeners();
    return isValid;
  }

  Future<bool> createGroup() async {
    if (!validateForm()) {
      return false;
    }

    // TODO: Replace with actual API call to create group
    await Future.delayed(const Duration(milliseconds: 500));

    return true;
  }

  @override
  void dispose() {
    groupNameController.dispose();
    elderlySearchController.dispose();
    caregiverSearchController.dispose();
    super.dispose();
  }
}
