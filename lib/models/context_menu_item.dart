import 'package:flutter/material.dart';

class ContextMenuItem {
  final String id;
  final String title;
  final String operation;
  final String aiInstruction;
  final IconData icon;
  final bool enabled;
  final int position;

  const ContextMenuItem({
    required this.id,
    required this.title,
    required this.operation,
    required this.aiInstruction,
    required this.icon,
    required this.enabled,
    required this.position,
  });

  ContextMenuItem copyWith({
    String? id,
    String? title,
    String? operation,
    String? aiInstruction,
    IconData? icon,
    bool? enabled,
    int? position,
  }) {
    return ContextMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      operation: operation ?? this.operation,
      aiInstruction: aiInstruction ?? this.aiInstruction,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'operation': operation,
      'aiInstruction': aiInstruction,
      'icon': icon.codePoint,
      'enabled': enabled,
      'position': position,
    };
  }

  factory ContextMenuItem.fromJson(Map<String, dynamic> json) {
    return ContextMenuItem(
      id: json['id'],
      title: json['title'],
      operation: json['operation'],
      aiInstruction: json['aiInstruction'] ?? '',
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      enabled: json['enabled'],
      position: json['position'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextMenuItem &&
        other.id == id &&
        other.title == title &&
        other.operation == operation &&
        other.aiInstruction == aiInstruction &&
        other.icon == icon &&
        other.enabled == enabled &&
        other.position == position;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        operation.hashCode ^
        aiInstruction.hashCode ^
        icon.hashCode ^
        enabled.hashCode ^
        position.hashCode;
  }

  @override
  String toString() {
    return 'ContextMenuItem(id: $id, title: $title, operation: $operation, aiInstruction: $aiInstruction, enabled: $enabled, position: $position)';
  }
}
