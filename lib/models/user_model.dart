class UserModel {
  final String id;
  String username;
  String email;
  String hashedPassword;
  int age;
  double heightCm;
  double weightKg;
  bool chronicDisease;
  String chronicDiseaseNotes;
  String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.hashedPassword,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.chronicDisease,
    required this.chronicDiseaseNotes,
    this.avatarUrl,
  });

  String getInitials() {
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }

  double getBMI() {
    final heightInMeters = heightCm / 100;
    return weightKg / (heightInMeters * heightInMeters);
  }

  UserModel copyWith({
    String? username,
    String? email,
    String? hashedPassword,
    int? age,
    double? heightCm,
    double? weightKg,
    bool? chronicDisease,
    String? chronicDiseaseNotes,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      chronicDisease: chronicDisease ?? this.chronicDisease,
      chronicDiseaseNotes: chronicDiseaseNotes ?? this.chronicDiseaseNotes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
