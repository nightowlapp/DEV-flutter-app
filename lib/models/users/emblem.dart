import 'package:flutter/foundation.dart';

@immutable
class Emblem { // TOdo look throrught and decide definitively.
  final String id;
  final String name;
  final String emoji;           // or icon in the future
  final String? description;
  final DateTime createdAt;
  final DateTime achievedAt;    // fixed typo
  final int points;
  final String reward;

  Emblem({
    required this.id,
    required this.name,
    required this.emoji,
    this.description,
    required this.createdAt,
    required this.achievedAt,
    required this.points,
    required this.reward,
  });

  // Accepts Firestore Timestamp, ISO String, int(ms), or DateTime.
  static DateTime _asDate(dynamic v, {DateTime? fallback}) {
    if (v == null) return fallback ?? DateTime.now();
    if (v is DateTime) return v;
    final type = v.runtimeType.toString();
    if (type == 'Timestamp') {
      final toDate = (v as dynamic).toDate as DateTime Function();
      return toDate();
    }
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v) ?? (fallback ?? DateTime.now());
    return fallback ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'achieved_at': achievedAt.toIso8601String(),
    'points': points,
    'reward': reward,
  }..removeWhere((_, v) => v == null);

  factory Emblem.fromJson(Map<String, dynamic> json) => Emblem(
    id: (json['id'] as String),
    name: (json['name'] as String).trim(),
    emoji: (json['emoji'] as String).trim(),
    description: (json['description'] as String?)?.trim(),
    createdAt: _asDate(json['created_at']),
    achievedAt: _asDate(json['achieved_at']),
    points: (json['points'] as num).toInt(),
    reward: (json['reward'] as String).trim(),
  );

  Emblem copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    DateTime? createdAt,
    DateTime? achievedAt,
    int? points,
    String? reward,
  }) =>
      Emblem(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
        achievedAt: achievedAt ?? this.achievedAt,
        points: points ?? this.points,
        reward: reward ?? this.reward,
      );

  @override
  bool operator ==(Object o) =>
      identical(this, o) ||
          (o is Emblem &&
              o.id == id &&
              o.name == name &&
              o.emoji == emoji &&
              o.description == description &&
              o.createdAt == createdAt &&
              o.achievedAt == achievedAt &&
              o.points == points &&
              o.reward == reward);

  @override
  int get hashCode =>
      Object.hash(id, name, emoji, description, createdAt, achievedAt, points, reward);
}
