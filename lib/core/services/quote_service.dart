import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:symphonia/core/constants/firebase_collections.dart';
import 'package:symphonia/core/logging/app_logger.dart';
import 'package:symphonia/core/services/auth_service.dart';

/// Daily Quote Model
class DailyQuote {
  const DailyQuote({
    required this.quote,
    required this.author,
    required this.date,
    this.isCustom = false,
    this.authorId,
  });
  final String quote;
  final String author;
  final DateTime date;
  final bool isCustom;
  final String? authorId;

  /// Default fallback quote
  static DailyQuote get defaultQuote => DailyQuote(
    quote: 'I love you infinity always',
    author: 'With Love',
    date: DateTime.now(),
  );
}

/// Daily Quote Provider - Streams custom quote directly from Firestore
/// Uses StreamProvider for real-time updates (same pattern as partner info)
final dailyQuoteProvider = StreamProvider<DailyQuote>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((u) => u.value?.coupleId),
  );

  if (coupleId == null) {
    return Stream.value(DailyQuote.defaultQuote);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) {
          return DailyQuote.defaultQuote;
        }

        final data = snapshot.data();
        final customQuoteData = data?['customQuote'] as Map<String, dynamic>?;

        if (customQuoteData == null || customQuoteData['quote'] == null) {
          return DailyQuote.defaultQuote;
        }

        return DailyQuote(
          quote: customQuoteData['quote'] as String? ?? '',
          author: customQuoteData['author'] as String? ?? 'Your Partner',
          date:
              (customQuoteData['setAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          isCustom: true,
          authorId: customQuoteData['authorId'] as String?,
        );
      });
});

/// Quote Service for setting/clearing quotes
final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService(ref);
});

class QuoteService {
  QuoteService(this._ref);
  final Ref _ref;

  /// Set a custom quote
  Future<void> setCustomQuote(String quote) async {
    if (quote.trim().isEmpty) return;

    final coupleId = _ref.read(
      currentAppUserProvider.select((u) => u.value?.coupleId),
    );
    final currentUser = _ref.read(currentAppUserProvider).value;

    if (coupleId == null || currentUser == null) return;

    try {
      final now = DateTime.now();

      await FirebaseFirestore.instance
          .collection(FirebaseCollections.couples)
          .doc(coupleId)
          .update({
            'customQuote': {
              'quote': quote.trim(),
              'author': currentUser.displayName,
              'authorId': currentUser.id,
              'setAt': Timestamp.fromDate(now),
            },
          });
    } catch (e) {
      AppLogger.error('Quote error', error: e);
      rethrow;
    }
  }

  /// Clear custom quote
  Future<void> clearCustomQuote() async {
    final coupleId = _ref.read(
      currentAppUserProvider.select((u) => u.value?.coupleId),
    );

    if (coupleId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.couples)
          .doc(coupleId)
          .update({'customQuote': FieldValue.delete()});
    } catch (e) {
      AppLogger.error('Quote error', error: e);
      rethrow;
    }
  }
}
