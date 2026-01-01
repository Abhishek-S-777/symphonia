import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_collections.dart';
import 'auth_service.dart';

/// Daily Quote Model
class DailyQuote {
  final String quote;
  final String author;
  final DateTime date;
  final bool isCustom;
  final String? authorId;

  const DailyQuote({
    required this.quote,
    required this.author,
    required this.date,
    this.isCustom = false,
    this.authorId,
  });

  /// Default fallback quote
  static DailyQuote get defaultQuote => DailyQuote(
    quote: 'I love you infinity always',
    author: 'With Love',
    date: DateTime.now(),
    isCustom: false,
  );
}

/// Daily Quote Provider - Streams custom quote directly from Firestore
/// Uses StreamProvider for real-time updates (same pattern as partner info)
final dailyQuoteProvider = StreamProvider<DailyQuote>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((u) => u.value?.coupleId),
  );

  if (coupleId == null) {
    debugPrint('Quote: coupleId is null, returning default');
    return Stream.value(DailyQuote.defaultQuote);
  }

  debugPrint('Quote: Streaming from Firestore for couple: $coupleId');

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

        debugPrint('Quote: Got custom quote from Firestore');
        return DailyQuote(
          quote: customQuoteData['quote'] ?? '',
          author: customQuoteData['author'] ?? 'Your Partner',
          date:
              (customQuoteData['setAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          isCustom: true,
          authorId: customQuoteData['authorId'],
        );
      });
});

/// Quote Service for setting/clearing quotes
final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService(ref);
});

class QuoteService {
  final Ref _ref;

  QuoteService(this._ref);

  /// Set a custom quote
  Future<void> setCustomQuote(String quote) async {
    if (quote.trim().isEmpty) return;

    final coupleId = _ref.read(
      currentAppUserProvider.select((u) => u.value?.coupleId),
    );
    final currentUser = _ref.read(currentAppUserProvider).value;

    if (coupleId == null || currentUser == null) {
      debugPrint('Quote: Cannot set - coupleId or user is null');
      return;
    }

    try {
      final now = DateTime.now();

      await FirebaseFirestore.instance
          .collection(FirebaseCollections.couples)
          .doc(coupleId)
          .update({
            'customQuote': {
              'quote': quote.trim(),
              'author': currentUser.displayName ?? 'Your Partner',
              'authorId': currentUser.id,
              'setAt': Timestamp.fromDate(now),
            },
          });

      debugPrint('Quote: Saved to Firestore');
    } catch (e) {
      debugPrint('Quote: Error saving: $e');
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

      debugPrint('Quote: Cleared from Firestore');
    } catch (e) {
      debugPrint('Quote: Error clearing: $e');
      rethrow;
    }
  }
}
