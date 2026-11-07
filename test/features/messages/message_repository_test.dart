import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symphonia/core/constants/firebase_collections.dart';
import 'package:symphonia/core/providers/firebase_providers.dart';
import 'package:symphonia/features/auth/data/auth_repository.dart';
import 'package:symphonia/features/auth/domain/entities/user.dart';
import 'package:symphonia/features/messages/data/message_repository.dart';
import 'package:symphonia/features/messages/domain/entities/message.dart';

/// Tests for [MessageRepository] and the message stream providers, backed by an
/// in-memory [FakeFirebaseFirestore]. These exercise the PR-5 data layer: the
/// repository and providers read Firestore through [firestoreProvider], so the
/// override swaps in the fake with no other changes.
void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  const coupleId = 'c1';
  final me = User(
    id: 'alice',
    email: 'alice@x.com',
    displayName: 'Alice',
    deviceId: 'd1',
    createdAt: DateTime(2024),
    lastActive: DateTime(2024),
    coupleId: coupleId,
  );

  CollectionReference<Map<String, dynamic>> messagesRef() => firestore
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.messages);

  Future<void> seedMessage({
    required String id,
    required String senderId,
    required String content,
    required DateTime sentAt,
    DateTime? readAt,
  }) {
    return messagesRef().doc(id).set({
      FirebaseCollections.messageSenderId: senderId,
      FirebaseCollections.messageContent: content,
      FirebaseCollections.messageType: MessageType.text.name,
      FirebaseCollections.messageSentAt: Timestamp.fromDate(sentAt),
      FirebaseCollections.messageReadAt: readAt != null
          ? Timestamp.fromDate(readAt)
          : null,
      FirebaseCollections.messageIsDelivered: true,
    });
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(firestore),
        currentAppUserProvider.overrideWith((ref) => Stream.value(me)),
      ],
    );
    // Keep the user provider alive and wait for its first emission so the
    // repository sees a signed-in, paired user.
    container.listen(currentAppUserProvider, (_, _) {});
    await container.read(currentAppUserProvider.future);
  });

  tearDown(() => container.dispose());

  MessageRepository repo() => container.read(messageRepositoryProvider);

  group('MessageRepository.sendMessage', () {
    test(
      'writes a text message under the couple with notification fields',
      () async {
        await repo().sendMessage(content: 'hello');

        final docs = (await messagesRef().get()).docs;
        expect(docs, hasLength(1));

        final data = docs.first.data();
        expect(data[FirebaseCollections.messageSenderId], 'alice');
        expect(data[FirebaseCollections.messageContent], 'hello');
        expect(data[FirebaseCollections.messageType], MessageType.text.name);
        expect(data['notificationType'], 'message');
        expect(data[FirebaseCollections.messageReadAt], isNull);
      },
    );

    test('sendHeartbeat records a heartbeat type and channel', () async {
      await repo().sendHeartbeat();

      final data = (await messagesRef().get()).docs.first.data();
      expect(data[FirebaseCollections.messageType], MessageType.heartbeat.name);
      expect(data['notificationType'], 'heartbeat');
      expect(data['notificationChannelId'], 'heartbeat_channel');
    });

    test('throws when the sender is not paired', () async {
      // copyWith cannot null a field, so build an unpaired user directly.
      final soloUser = User(
        id: 'alice',
        email: 'alice@x.com',
        displayName: 'Alice',
        deviceId: 'd1',
        createdAt: DateTime(2024),
        lastActive: DateTime(2024),
      );
      final soloContainer = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          currentAppUserProvider.overrideWith((ref) => Stream.value(soloUser)),
        ],
      );
      addTearDown(soloContainer.dispose);
      soloContainer.listen(currentAppUserProvider, (_, _) {});
      await soloContainer.read(currentAppUserProvider.future);

      expect(
        () => soloContainer
            .read(messageRepositoryProvider)
            .sendMessage(
              content: 'hi',
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MessageRepository read receipts', () {
    test('markAsRead stamps the readAt field', () async {
      await seedMessage(
        id: 'm1',
        senderId: 'bob',
        content: 'hi',
        sentAt: DateTime(2024, 1, 2),
      );

      await repo().markAsRead('m1');

      final data = (await messagesRef().doc('m1').get()).data()!;
      expect(data[FirebaseCollections.messageReadAt], isNotNull);
    });

    test('markAllAsRead only marks messages from the partner', () async {
      await seedMessage(
        id: 'fromBob',
        senderId: 'bob',
        content: 'hi',
        sentAt: DateTime(2024, 1, 2),
      );
      await seedMessage(
        id: 'fromMe',
        senderId: 'alice',
        content: 'mine',
        sentAt: DateTime(2024, 1, 3),
      );

      await repo().markAllAsRead();

      final bob = (await messagesRef().doc('fromBob').get()).data()!;
      final mine = (await messagesRef().doc('fromMe').get()).data()!;
      expect(bob[FirebaseCollections.messageReadAt], isNotNull);
      expect(mine[FirebaseCollections.messageReadAt], isNull);
    });
  });

  group('messagesStreamProvider', () {
    test('maps documents to entities newest first', () async {
      await seedMessage(
        id: 'older',
        senderId: 'bob',
        content: 'first',
        sentAt: DateTime(2024, 1, 1, 9),
      );
      await seedMessage(
        id: 'newer',
        senderId: 'alice',
        content: 'second',
        sentAt: DateTime(2024, 1, 1, 10),
      );

      container.listen(messagesStreamProvider, (_, _) {});
      final messages = await container.read(messagesStreamProvider.future);

      expect(messages, hasLength(2));
      expect(messages.first.content, 'second');
      expect(messages.last.content, 'first');
      expect(messages.first.type, MessageType.text);
    });
  });

  group('unreadMessagesCountProvider', () {
    test('counts only unread messages from the partner', () async {
      await seedMessage(
        id: 'unreadFromBob',
        senderId: 'bob',
        content: 'unread',
        sentAt: DateTime(2024, 1, 1, 9),
      );
      await seedMessage(
        id: 'readFromBob',
        senderId: 'bob',
        content: 'read',
        sentAt: DateTime(2024, 1, 1, 10),
        readAt: DateTime(2024, 1, 1, 11),
      );
      await seedMessage(
        id: 'fromMe',
        senderId: 'alice',
        content: 'mine',
        sentAt: DateTime(2024, 1, 1, 12),
      );

      container.listen(unreadMessagesCountProvider, (_, _) {});
      final count = await container.read(unreadMessagesCountProvider.future);
      expect(count, 1);
    });
  });
}
