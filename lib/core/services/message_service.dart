import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_collections.dart';
import '../../features/messages/domain/entities/message.dart';
import 'auth_service.dart';
import 'fcm_service.dart';

/// Message Service Provider
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(ref);
});

/// Messages Stream Provider
final messagesStreamProvider = StreamProvider<List<Message>>((ref) {
  final currentUser = ref.watch(currentAppUserProvider).value;
  if (currentUser == null || currentUser.coupleId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(currentUser.coupleId)
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
final latestReceivedHeartbeatProvider = StreamProvider<Message?>((ref) {
  final currentUser = ref.watch(currentAppUserProvider).value;
  if (currentUser == null || currentUser.coupleId == null) {
    return Stream.value(null);
  }

  // Only get heartbeats from the last 30 seconds that are from the partner
  final thirtySecondsAgo = DateTime.now().subtract(const Duration(seconds: 30));

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(currentUser.coupleId)
      .collection(FirebaseCollections.messages)
      .where(FirebaseCollections.messageType, isEqualTo: 'heartbeat')
      .where(FirebaseCollections.messageSenderId, isNotEqualTo: currentUser.id)
      .orderBy(FirebaseCollections.messageSenderId)
      .orderBy(FirebaseCollections.messageSentAt, descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        final message = _messageFromFirestore(snapshot.docs.first);
        // Only return if it's recent (within last 30 seconds)
        if (message.sentAt.isAfter(thirtySecondsAgo)) {
          return message;
        }
        return null;
      });
});

/// Unread Messages Count Provider
final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final currentUser = ref.watch(currentAppUserProvider).value;
  if (currentUser == null || currentUser.coupleId == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(currentUser.coupleId)
      .collection(FirebaseCollections.messages)
      .where(FirebaseCollections.messageSenderId, isNotEqualTo: currentUser.id)
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

    await messageRef.set({
      FirebaseCollections.messageSenderId: currentUser.id,
      FirebaseCollections.messageContent: content,
      FirebaseCollections.messageType: type.name,
      FirebaseCollections.messageSentAt: FieldValue.serverTimestamp(),
      FirebaseCollections.messageReadAt: null,
      FirebaseCollections.messageIsDelivered: true,
    });

    // Send push notification to partner
    _sendNotificationToPartner(
      title: currentUser.displayName,
      body: type == MessageType.heartbeat
          ? '💓 sent you a heartbeat!'
          : content,
      type: type == MessageType.heartbeat ? 'heartbeat' : 'message',
    );
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

  /// Send notification to partner
  Future<void> _sendNotificationToPartner({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final fcmService = _ref.read(fcmServiceProvider);
      final partner = _ref.read(partnerUserProvider).value;

      if (partner?.fcmToken != null) {
        await fcmService.sendNotificationToToken(
          token: partner!.fcmToken!,
          title: title,
          body: body,
          data: {'type': type},
        );
      }
    } catch (e) {
      // Ignore notification errors
    }
  }
}
