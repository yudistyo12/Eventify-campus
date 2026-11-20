class UserModel {
  final String uid;
  final String name;
  final String email;
  final String nim; // Student ID
  final String major; // Major/Department
  final String role; // 'user' atau 'admin'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.nim,
    required this.major,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'nim': nim,
      'major': major,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      nim: map['nim'] ?? '',
      major: map['major'] ?? '',
      role: map['role'] ?? 'user',
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? nim,
    String? major,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      major: major ?? this.major,
      role: role ?? this.role,
    );
  }
}
