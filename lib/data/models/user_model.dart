class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String role;
  final List<String> childIds;
  final String? pin;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.role = 'parent',
    this.childIds = const [],
    this.pin,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      role: map['role'] ?? 'parent',
      childIds: List<String>.from(map['childIds'] ?? []),
      pin: map['pin'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'childIds': childIds,
      'pin': pin,
    };
  }
}
