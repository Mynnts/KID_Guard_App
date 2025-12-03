import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String? avatar;
  final int screenTime; // in seconds
  final bool isLocked;
  final bool isOnline;
  final DateTime? lastActive;
  final int dailyTimeLimit; // in seconds, 0 means no limit
  final bool isChildModeActive;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.avatar,
    this.screenTime = 0,
    this.isLocked = false,
    this.isOnline = false,
    this.lastActive,
    this.dailyTimeLimit = 0,
    this.isChildModeActive = false,
  });

  factory ChildModel.fromMap(Map<String, dynamic> map, String id) {
    return ChildModel(
      id: id,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      avatar: map['avatar'],
      screenTime: map['screenTime'] ?? 0,
      isLocked: map['isLocked'] ?? false,
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] as Timestamp).toDate()
          : null,
      dailyTimeLimit: map['dailyTimeLimit'] ?? 0,
      isChildModeActive: map['isChildModeActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'age': age,
      'avatar': avatar,
      'screenTime': screenTime,
      'isLocked': isLocked,
      'isOnline': isOnline,
      'lastActive': lastActive,
      'dailyTimeLimit': dailyTimeLimit,
      'isChildModeActive': isChildModeActive,
    };
  }
}
