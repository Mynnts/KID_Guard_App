class AppInfoModel {
  final String packageName;
  final String name;
  final bool isSystemApp;
  final bool isLocked;
  final String? iconBase64;

  AppInfoModel({
    required this.packageName,
    required this.name,
    required this.isSystemApp,
    this.isLocked = false,
    this.iconBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'name': name,
      'isSystemApp': isSystemApp,
      'isLocked': isLocked,
      'iconBase64': iconBase64,
    };
  }

  factory AppInfoModel.fromMap(Map<String, dynamic> map) {
    return AppInfoModel(
      packageName: map['packageName'] ?? '',
      name: map['name'] ?? '',
      isSystemApp: map['isSystemApp'] ?? false,
      isLocked: map['isLocked'] ?? false,
      iconBase64: map['iconBase64'],
    );
  }

  AppInfoModel copyWith({
    String? packageName,
    String? name,
    bool? isSystemApp,
    bool? isLocked,
    String? iconBase64,
  }) {
    return AppInfoModel(
      packageName: packageName ?? this.packageName,
      name: name ?? this.name,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isLocked: isLocked ?? this.isLocked,
      iconBase64: iconBase64 ?? this.iconBase64,
    );
  }
}
