import 'package:equatable/equatable.dart';

/// Memory entity for gallery/timeline
class Memory extends Equatable {
  const Memory({
    required this.id,
    required this.creatorId,
    required this.imageUrls,
    required this.localPaths,
    required this.date,
    required this.createdAt,
    this.note,
    this.isSynced = false,
  });
  final String id;
  final String creatorId;
  final List<String> imageUrls;
  final List<String> localPaths;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final bool isSynced;

  /// Check if memory is from me
  bool isFromMe(String myUserId) => creatorId == myUserId;

  /// Check if memory has a note
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Number of images
  int get imageCount => imageUrls.length + localPaths.length;

  /// Check if memory has multiple images
  bool get hasMultipleImages => imageCount > 1;

  /// Get primary image (first one)
  String? get primaryImage {
    if (localPaths.isNotEmpty) return localPaths.first;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }

  /// Check if memory needs upload
  bool get needsUpload => localPaths.isNotEmpty && !isSynced;

  Memory copyWith({
    String? id,
    String? creatorId,
    List<String>? imageUrls,
    List<String>? localPaths,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Memory(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      imageUrls: imageUrls ?? this.imageUrls,
      localPaths: localPaths ?? this.localPaths,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    creatorId,
    imageUrls,
    localPaths,
    note,
    date,
    createdAt,
    isSynced,
  ];
}
