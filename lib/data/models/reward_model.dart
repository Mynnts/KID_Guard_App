import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String id;
  final String name;
  final String emoji;
  final int cost;
  final DateTime createdAt;

  RewardModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.createdAt,
  });

  factory RewardModel.fromMap(Map<String, dynamic> map, String id) {
    return RewardModel(
      id: id,
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '⭐',
      cost: map['cost'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'cost': cost,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RewardModel copyWith({String? name, String? emoji, int? cost}) {
    return RewardModel(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      cost: cost ?? this.cost,
      createdAt: createdAt,
    );
  }
}
