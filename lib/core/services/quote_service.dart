import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../constants/firebase_collections.dart';
import 'auth_service.dart';

/// Daily Quote Provider - Uses AsyncNotifier for reactive updates with caching
final dailyQuoteProvider =
    AsyncNotifierProvider<DailyQuoteNotifier, DailyQuote>(() {
      return DailyQuoteNotifier();
    });

/// Quote Service Provider
final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService();
});

/// Daily Quote Model
class DailyQuote {
  final String quote;
  final String author;
  final DateTime date;
  final bool isCustom;
  final String? authorId; // User ID who set the custom quote
  final DateTime? customSetAt; // When custom quote was set

  const DailyQuote({
    required this.quote,
    required this.author,
    required this.date,
    this.isCustom = false,
    this.authorId,
    this.customSetAt,
  });

  Map<String, dynamic> toJson() => {
    'quote': quote,
    'author': author,
    'date': date.toIso8601String(),
    'isCustom': isCustom,
    'authorId': authorId,
    'customSetAt': customSetAt?.toIso8601String(),
  };

  factory DailyQuote.fromJson(Map<String, dynamic> json) => DailyQuote(
    quote: json['quote'] ?? '',
    author: json['author'] ?? 'Unknown',
    date: DateTime.parse(json['date']),
    isCustom: json['isCustom'] ?? false,
    authorId: json['authorId'],
    customSetAt: json['customSetAt'] != null
        ? DateTime.parse(json['customSetAt'])
        : null,
  );

  DailyQuote copyWith({
    String? quote,
    String? author,
    DateTime? date,
    bool? isCustom,
    String? authorId,
    DateTime? customSetAt,
  }) {
    return DailyQuote(
      quote: quote ?? this.quote,
      author: author ?? this.author,
      date: date ?? this.date,
      isCustom: isCustom ?? this.isCustom,
      authorId: authorId ?? this.authorId,
      customSetAt: customSetAt ?? this.customSetAt,
    );
  }
}

/// AsyncNotifier for managing daily quote with caching
class DailyQuoteNotifier extends AsyncNotifier<DailyQuote> {
  static const String _cacheKey = 'daily_quote_cache_v2';
  static const String _cacheDateKey = 'daily_quote_date_v2';

  @override
  Future<DailyQuote> build() async {
    // Start listening for partner updates
    _listenForPartnerUpdates();

    // Load quote with caching strategy
    return await _loadQuote();
  }

  /// Load quote: Cache → Firestore (custom) → API
  Future<DailyQuote> _loadQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();

      // Step 1: Try to load from cache
      final cachedQuote = await _loadFromCache(prefs);

      if (cachedQuote != null) {
        // If it's a custom quote, it never expires
        if (cachedQuote.isCustom) {
          return cachedQuote;
        }

        // For API quotes, check if it's still today
        final cachedDateStr = prefs.getString(_cacheDateKey);
        if (cachedDateStr == today) {
          return cachedQuote;
        }
      }

      // Step 2: Check Firestore for custom quote
      final firestoreQuote = await _fetchFromFirestore();
      if (firestoreQuote != null && firestoreQuote.isCustom) {
        await _saveToCache(prefs, firestoreQuote);
        return firestoreQuote;
      }

      // Step 3: Fetch from API (no custom quote)
      final apiQuote = await _fetchFromAPI();
      await _saveToCache(prefs, apiQuote);
      await prefs.setString(_cacheDateKey, today);
      return apiQuote;
    } catch (e) {
      // On error, use fallback quote
      return QuoteService.getRandomFallbackQuote();
    }
  }

  /// Listen for partner updates via Firestore
  void _listenForPartnerUpdates() {
    final coupleId = ref.read(
      currentAppUserProvider.select((u) => u.value?.coupleId),
    );

    if (coupleId == null) return;

    FirebaseFirestore.instance
        .collection(FirebaseCollections.couples)
        .doc(coupleId)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists) return;

          final data = snapshot.data();
          final customQuoteData = data?['customQuote'] as Map<String, dynamic>?;

          if (customQuoteData != null && customQuoteData['quote'] != null) {
            final firestoreQuote = DailyQuote(
              quote: customQuoteData['quote'] ?? '',
              author: customQuoteData['author'] ?? 'Unknown',
              date:
                  (customQuoteData['setAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              isCustom: true,
              authorId: customQuoteData['authorId'],
              customSetAt: (customQuoteData['setAt'] as Timestamp?)?.toDate(),
            );

            // Update cache and state
            final prefs = await SharedPreferences.getInstance();
            await _saveToCache(prefs, firestoreQuote);
            state = AsyncValue.data(firestoreQuote);
          } else if (state.value?.isCustom == true) {
            // Custom quote was cleared by partner, refresh API quote
            await _refreshApiQuote();
          }
        });
  }

  /// Set a custom quote
  Future<void> setCustomQuote(String quote) async {
    if (quote.trim().isEmpty) return;

    final coupleId = ref.read(
      currentAppUserProvider.select((u) => u.value?.coupleId),
    );
    final currentUser = ref.read(currentAppUserProvider).value;

    if (coupleId == null || currentUser == null) return;

    state = const AsyncValue.loading();

    try {
      final now = DateTime.now();

      // Save to Firestore (this will notify partner via listener)
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

      final customQuote = DailyQuote(
        quote: quote.trim(),
        author: currentUser.displayName ?? 'Your Partner',
        date: now,
        isCustom: true,
        authorId: currentUser.id,
        customSetAt: now,
      );

      // Update cache
      final prefs = await SharedPreferences.getInstance();
      await _saveToCache(prefs, customQuote);

      state = AsyncValue.data(customQuote);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear custom quote and fetch new API quote
  Future<void> clearCustomQuote() async {
    final coupleId = ref.read(
      currentAppUserProvider.select((u) => u.value?.coupleId),
    );

    if (coupleId == null) return;

    state = const AsyncValue.loading();

    try {
      // Clear from Firestore
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.couples)
          .doc(coupleId)
          .update({'customQuote': FieldValue.delete()});

      // Fetch new API quote
      await _refreshApiQuote();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh API quote
  Future<void> _refreshApiQuote() async {
    try {
      final apiQuote = await _fetchFromAPI();
      final prefs = await SharedPreferences.getInstance();
      await _saveToCache(prefs, apiQuote);
      await prefs.setString(_cacheDateKey, _getTodayString());
      state = AsyncValue.data(apiQuote);
    } catch (e) {
      final fallback = QuoteService.getRandomFallbackQuote();
      state = AsyncValue.data(fallback);
    }
  }

  /// Force refresh (for pull-to-refresh or manual refresh)
  Future<void> refresh() async {
    // If currently showing custom quote, don't refresh
    if (state.value?.isCustom == true) {
      return;
    }
    state = const AsyncValue.loading();
    await _refreshApiQuote();
  }

  // Helper methods
  String _getTodayString() {
    final today = DateTime.now();
    return '${today.year}-${today.month}-${today.day}';
  }

  Future<DailyQuote?> _loadFromCache(SharedPreferences prefs) async {
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null) {
      try {
        return DailyQuote.fromJson(json.decode(cachedJson));
      } catch (_) {}
    }
    return null;
  }

  Future<void> _saveToCache(SharedPreferences prefs, DailyQuote quote) async {
    await prefs.setString(_cacheKey, json.encode(quote.toJson()));
  }

  Future<DailyQuote?> _fetchFromFirestore() async {
    final coupleId = ref.read(
      currentAppUserProvider.select((u) => u.value?.coupleId),
    );

    if (coupleId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.couples)
          .doc(coupleId)
          .get();

      if (!doc.exists) return null;

      final customQuoteData =
          doc.data()?['customQuote'] as Map<String, dynamic>?;
      if (customQuoteData == null || customQuoteData['quote'] == null) {
        return null;
      }

      return DailyQuote(
        quote: customQuoteData['quote'] ?? '',
        author: customQuoteData['author'] ?? 'Unknown',
        date:
            (customQuoteData['setAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        isCustom: true,
        authorId: customQuoteData['authorId'],
        customSetAt: (customQuoteData['setAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      debugPrint('Error fetching quote from Firestore: $e');
      return null;
    }
  }

  Future<DailyQuote> _fetchFromAPI() async {
    final quoteService = ref.read(quoteServiceProvider);
    return await quoteService.fetchQuoteFromAPI();
  }
}

/// Quote Service for fetching daily love quotes
class QuoteService {
  /// Romantic/Love quotes fallback list
  static const List<Map<String, String>> _fallbackQuotes = [
    {
      'quote':
          'In all the world, there is no heart for me like yours. In all the world, there is no love for you like mine.',
      'author': 'Maya Angelou',
    },
    {
      'quote':
          'I have waited for this opportunity for more than half a century, to repeat to you once again my vow of eternal fidelity and everlasting love.',
      'author': 'Gabriel García Márquez',
    },
    {
      'quote': 'Whatever our souls are made of, his and mine are the same.',
      'author': 'Emily Brontë',
    },
    {
      'quote':
          'You know you\'re in love when you can\'t fall asleep because reality is finally better than your dreams.',
      'author': 'Dr. Seuss',
    },
    {
      'quote':
          'I would rather spend one lifetime with you, than face all the ages of this world alone.',
      'author': 'J.R.R. Tolkien',
    },
    {
      'quote': 'The best thing to hold onto in life is each other.',
      'author': 'Audrey Hepburn',
    },
    {
      'quote': 'Love is composed of a single soul inhabiting two bodies.',
      'author': 'Aristotle',
    },
    {
      'quote':
          'I love you not only for what you are, but for what I am when I am with you.',
      'author': 'Roy Croft',
    },
    {
      'quote': 'To love and be loved is to feel the sun from both sides.',
      'author': 'David Viscott',
    },
    {
      'quote':
          'The greatest thing you\'ll ever learn is just to love and be loved in return.',
      'author': 'Eden Ahbez',
    },
    {
      'quote':
          'Love recognizes no barriers. It jumps hurdles, leaps fences, penetrates walls to arrive at its destination full of hope.',
      'author': 'Maya Angelou',
    },
    {
      'quote': 'You are my today and all of my tomorrows.',
      'author': 'Leo Christopher',
    },
    {
      'quote':
          'I saw that you were perfect, and so I loved you. Then I saw that you were not perfect and I loved you even more.',
      'author': 'Angelita Lim',
    },
    {
      'quote':
          'Love is when the other person\'s happiness is more important than your own.',
      'author': 'H. Jackson Brown Jr.',
    },
    {
      'quote':
          'The heart wants what it wants. There\'s no logic to these things.',
      'author': 'Woody Allen',
    },
    {'quote': 'Where there is love there is life.', 'author': 'Mahatma Gandhi'},
    {
      'quote':
          'Being deeply loved by someone gives you strength, while loving someone deeply gives you courage.',
      'author': 'Lao Tzu',
    },
    {
      'quote':
          'There is only one happiness in this life, to love and be loved.',
      'author': 'George Sand',
    },
    {
      'quote': 'Love is a friendship set to music.',
      'author': 'Joseph Campbell',
    },
    {
      'quote':
          'The best love is the kind that awakens the soul and makes us reach for more.',
      'author': 'Nicholas Sparks',
    },
    {
      'quote':
          'Love is not about how many days, months, or years you have been together. Love is about how much you love each other every single day.',
      'author': 'Unknown',
    },
    {
      'quote':
          'I fell in love the way you fall asleep: slowly, and then all at once.',
      'author': 'John Green',
    },
    {
      'quote':
          'When I saw you, I fell in love, and you smiled because you knew.',
      'author': 'Arrigo Boito',
    },
    {
      'quote':
          'Love does not consist in gazing at each other, but in looking outward together in the same direction.',
      'author': 'Antoine de Saint-Exupéry',
    },
    {
      'quote': 'If I know what love is, it is because of you.',
      'author': 'Hermann Hesse',
    },
    {
      'quote':
          'You are the finest, loveliest, tenderest, and most beautiful person I have ever known.',
      'author': 'F. Scott Fitzgerald',
    },
    {
      'quote': 'Grow old with me! The best is yet to be.',
      'author': 'Robert Browning',
    },
    {
      'quote':
          'Two souls with but a single thought, two hearts that beat as one.',
      'author': 'John Keats',
    },
    {
      'quote': 'My heart is, and always will be, yours.',
      'author': 'Jane Austen',
    },
    {
      'quote': 'Love is friendship that has caught fire.',
      'author': 'Ann Landers',
    },
    {'quote': 'In your light, I learn how to love.', 'author': 'Rumi'},
  ];

  /// Fetch quote from API
  Future<DailyQuote> fetchQuoteFromAPI() async {
    DailyQuote? quote;

    try {
      // Try ZenQuotes API (free, no auth required)
      final response = await http
          .get(Uri.parse('https://zenquotes.io/api/today'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final quoteData = data[0];
          quote = DailyQuote(
            quote: quoteData['q'] ?? '',
            author: quoteData['a'] ?? 'Unknown',
            date: DateTime.now(),
            isCustom: false,
          );
        }
      }
    } catch (_) {
      // Try alternative: Quotable API
      try {
        final response = await http
            .get(Uri.parse('https://api.quotable.io/random?tags=love'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          quote = DailyQuote(
            quote: data['content'] ?? '',
            author: data['author'] ?? 'Unknown',
            date: DateTime.now(),
            isCustom: false,
          );
        }
      } catch (_) {}
    }

    return quote ?? getRandomFallbackQuote();
  }

  /// Get a random quote from fallback list
  /// Uses the day of year as seed to get consistent quote per day
  static DailyQuote getRandomFallbackQuote() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _fallbackQuotes.length;

    final quote = _fallbackQuotes[index];
    return DailyQuote(
      quote: quote['quote']!,
      author: quote['author']!,
      date: now,
      isCustom: false,
    );
  }
}
