import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Note entity for storing rich text notes
class Note extends Equatable {
  final String id;
  final String creatorId;
  final String title;
  final String content; // JSON Delta format from Quill
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get plain text preview from Quill Delta content
  String get plainTextPreview {
    try {
      final deltaJson = jsonDecode(content);
      if (deltaJson is List) {
        final buffer = StringBuffer();
        for (final op in deltaJson) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        final text = buffer.toString().trim();
        return text.length > 100 ? '${text.substring(0, 100)}...' : text;
      }
    } catch (_) {}
    return '';
  }

  Note copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    creatorId,
    title,
    content,
    createdAt,
    updatedAt,
  ];
}
