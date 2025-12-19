import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_collections.dart';
import '../../features/messages/domain/entities/message.dart';
import 'auth_service.dart';

/// Message Service Provider
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(ref);
});

/// Messages Stream Provider
/// Uses select() to only rebuild when coupleId changes
final messagesStreamProvider = StreamProvider<List<Message>>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.coupleId),
  );
  if (coupleId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.messages)
      .orderBy(FirebaseCollections.messageSentAt, descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => _messageFromFirestore(doc)).toList();
      });
});

/// Latest Received Heartbeat Provider - listens for new heartbeats from partner
/// This triggers vibration on the receiver's device
/// Uses select() to only rebuild when coupleId or userId changes
final latestReceivedHeartbeatProvider = StreamProvider<Message?>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.coupleId),
  );
  final userId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.id),
  );
  if (coupleId == null || userId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.messages)
      .where(FirebaseCollections.messageType, isEqualTo: 'heartbeat')
      .where(FirebaseCollections.messageSenderId, isNotEqualTo: userId)
      .orderBy(FirebaseCollections.messageSenderId)
      .orderBy(FirebaseCollections.messageSentAt, descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        final message = _messageFromFirestore(snapshot.docs.first);
        // Check timestamp dynamically at map time, not at provider creation
        final now = DateTime.now();
        final thirtySecondsAgo = now.subtract(const Duration(seconds: 30));
        // Only return if it's recent (within last 30 seconds)
        if (message.sentAt.isAfter(thirtySecondsAgo)) {
          return message;
        }
        return null;
      });
});

/// Unread Messages Count Provider
/// Uses select() to only rebuild when coupleId or userId changes
final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.coupleId),
  );
  final userId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.id),
  );
  if (coupleId == null || userId == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.messages)
      .where(FirebaseCollections.messageSenderId, isNotEqualTo: userId)
      .where(FirebaseCollections.messageReadAt, isNull: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

Message _messageFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Message(
    id: doc.id,
    senderId: data[FirebaseCollections.messageSenderId] ?? '',
    content: data[FirebaseCollections.messageContent] ?? '',
    type: MessageType.values.firstWhere(
      (e) => e.name == data[FirebaseCollections.messageType],
      orElse: () => MessageType.text,
    ),
    scheduledFor: (data[FirebaseCollections.messageScheduledFor] as Timestamp?)
        ?.toDate(),
    sentAt:
        (data[FirebaseCollections.messageSentAt] as Timestamp?)?.toDate() ??
        DateTime.now(),
    readAt: (data[FirebaseCollections.messageReadAt] as Timestamp?)?.toDate(),
    isDelivered: data[FirebaseCollections.messageIsDelivered] ?? true,
    isSynced: true,
  );
}

/// Message Service for sending and receiving messages
class MessageService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MessageService(this._ref);

  /// Send a text message
  Future<void> sendMessage({
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      throw Exception('User not paired');
    }

    final messageRef = _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.messages)
        .doc();

    // Prepare notification data based on message type
    String notificationTitle;
    String notificationBody;
    String notificationChannelId;
    String notificationType;

    if (type == MessageType.heartbeat) {
      notificationTitle = 'My 💓 beats for you';
      notificationBody = '${currentUser.displayName} sent you love!';
      notificationChannelId = 'heartbeat_channel';
      notificationType = 'heartbeat';
    } else {
      notificationTitle = currentUser.displayName;
      notificationBody = content.length > 100
          ? '${content.substring(0, 100)}...'
          : content;
      notificationChannelId = 'message_channel';
      notificationType = 'message';
    }

    await messageRef.set({
      FirebaseCollections.messageSenderId: currentUser.id,
      FirebaseCollections.messageContent: content,
      FirebaseCollections.messageType: type.name,
      FirebaseCollections.messageSentAt: FieldValue.serverTimestamp(),
      FirebaseCollections.messageReadAt: null,
      FirebaseCollections.messageIsDelivered: true,
      // Notification fields - Cloud Function will read and forward these
      'notificationTitle': notificationTitle,
      'notificationBody': notificationBody,
      'notificationChannelId': notificationChannelId,
      'notificationType': notificationType,
    });
  }

  /// Send a heartbeat
  Future<void> sendHeartbeat() async {
    await sendMessage(content: '💓', type: MessageType.heartbeat);
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.messages)
        .doc(messageId)
        .update({
          FirebaseCollections.messageReadAt: FieldValue.serverTimestamp(),
        });
  }

  /// Mark all messages as read
  Future<void> markAllAsRead() async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    final unreadMessages = await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.messages)
        .where(
          FirebaseCollections.messageSenderId,
          isNotEqualTo: currentUser.id,
        )
        .where(FirebaseCollections.messageReadAt, isNull: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        FirebaseCollections.messageReadAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.messages)
        .doc(messageId)
        .delete();
  }
}
