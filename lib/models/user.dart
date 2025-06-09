class AppUser {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}