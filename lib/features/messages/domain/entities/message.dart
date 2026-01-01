import 'package:equatable/equatable.dart';

/// Message types
enum MessageType { text, predefined, scheduled, heartbeat, hugs }

/// Message entity for love messages
class Message extends Equatable {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime? scheduledFor;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isDelivered;
  final bool isSynced;

  const Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    this.scheduledFor,
    required this.sentAt,
    this.readAt,
    this.isDelivered = false,
    this.isSynced = false,
  });

  /// Check if message is from me
  bool isFromMe(String myUserId) => senderId == myUserId;

  /// Check if message has been read
  bool get isRead => readAt != null;

  /// Check if message is scheduled for future
  bool get isScheduled =>
      scheduledFor != null && scheduledFor!.isAfter(DateTime.now());

  /// Check if message is a heartbeat
  bool get isHeartbeat => type == MessageType.heartbeat;

  Message copyWith({
    String? id,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? readAt,
    bool? isDelivered,
    bool? isSynced,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      isDelivered: isDelivered ?? this.isDelivered,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    content,
    type,
    scheduledFor,
    sentAt,
    readAt,
    isDelivered,
    isSynced,
  ];
}
