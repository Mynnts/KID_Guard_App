class ContactModel {
  final String id;
  final String displayName;
  final List<String> phones;
  final String? avatar; // Base64 or URL

  ContactModel({
    required this.id,
    required this.displayName,
    required this.phones,
    this.avatar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'phones': phones,
      'avatar': avatar,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      phones: List<String>.from(map['phones'] ?? []),
      avatar: map['avatar'],
    );
  }
}
