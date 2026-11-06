import 'package:flutter/material.dart';

class ClassroomModel {
  final String id;
  final String name;
  final int minAgeYears;
  final int maxAgeYears;
  final int maxCapacity;
  final int colorValue;
  final DateTime? createdAt;

  const ClassroomModel({
    required this.id,
    required this.name,
    required this.minAgeYears,
    required this.maxAgeYears,
    required this.maxCapacity,
    this.colorValue = 0xFF007FFF,
    this.createdAt,
  });

  Color get color => Color(colorValue);

  String get ageRangeFormatted {
    if (minAgeYears == 0 && maxAgeYears == 0) {
      return 'Até 1 ano';
    } else if (minAgeYears == maxAgeYears) {
      return '$minAgeYears anos';
    } else {
      return '$minAgeYears a $maxAgeYears anos';
    }
  }

  factory ClassroomModel.fromMap(Map<String, dynamic> map) {
    return ClassroomModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      minAgeYears: int.tryParse(map['min_age_years']?.toString() ?? '0') ?? 0,
      maxAgeYears: int.tryParse(map['max_age_years']?.toString() ?? '12') ?? 12,
      maxCapacity: int.tryParse(map['max_capacity']?.toString() ?? '20') ?? 20,
      colorValue: int.tryParse(map['color_value']?.toString() ?? '4278222847') ?? 0xFF007FFF,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'min_age_years': minAgeYears,
      'max_age_years': maxAgeYears,
      'max_capacity': maxCapacity,
      'color_value': colorValue,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
    };
  }

  ClassroomModel copyWith({
    String? id,
    String? name,
    int? minAgeYears,
    int? maxAgeYears,
    int? maxCapacity,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return ClassroomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minAgeYears: minAgeYears ?? this.minAgeYears,
      maxAgeYears: maxAgeYears ?? this.maxAgeYears,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
