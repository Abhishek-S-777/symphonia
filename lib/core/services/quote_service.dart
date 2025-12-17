import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Daily Quote Provider
final dailyQuoteProvider = FutureProvider<DailyQuote>((ref) async {
  final quoteService = ref.watch(quoteServiceProvider);
  return await quoteService.getDailyQuote();
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

  const DailyQuote({
    required this.quote,
    required this.author,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'quote': quote,
    'author': author,
    'date': date.toIso8601String(),
  };

  factory DailyQuote.fromJson(Map<String, dynamic> json) => DailyQuote(
    quote: json['quote'] ?? '',
    author: json['author'] ?? 'Unknown',
    date: DateTime.parse(json['date']),
  );
}

/// Quote Service for fetching daily love quotes
class QuoteService {
  static const String _cacheKey = 'daily_quote_cache';
  static const String _cacheDateKey = 'daily_quote_date';

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

  /// Get daily quote - checks cache first, then fetches new if needed
  Future<DailyQuote> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have a cached quote for today
    final cachedDateStr = prefs.getString(_cacheDateKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (cachedDateStr == todayStr) {
      // Return cached quote
      final cachedQuote = prefs.getString(_cacheKey);
      if (cachedQuote != null) {
        try {
          return DailyQuote.fromJson(json.decode(cachedQuote));
        } catch (_) {}
      }
    }

    // Try to fetch from API first
    DailyQuote? quote;
    try {
      quote = await _fetchQuoteFromAPI();
    } catch (_) {
      // Fall back to local quotes
    }

    // If API failed, use fallback
    quote ??= _getRandomFallbackQuote();

    // Cache the quote
    await prefs.setString(_cacheKey, json.encode(quote.toJson()));
    await prefs.setString(_cacheDateKey, todayStr);

    return quote;
  }

  /// Fetch quote from a free API
  Future<DailyQuote?> _fetchQuoteFromAPI() async {
    try {
      // Try ZenQuotes API (free, no auth required)
      final response = await http
          .get(Uri.parse('https://zenquotes.io/api/today'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final quoteData = data[0];
          return DailyQuote(
            quote: quoteData['q'] ?? '',
            author: quoteData['a'] ?? 'Unknown',
            date: DateTime.now(),
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
          return DailyQuote(
            quote: data['content'] ?? '',
            author: data['author'] ?? 'Unknown',
            date: DateTime.now(),
          );
        }
      } catch (_) {}
    }

    return null;
  }

  /// Get a random quote from fallback list
  /// Uses the day of year as seed to get consistent quote per day
  DailyQuote _getRandomFallbackQuote() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _fallbackQuotes.length;

    final quote = _fallbackQuotes[index];
    return DailyQuote(
      quote: quote['quote']!,
      author: quote['author']!,
      date: now,
    );
  }

  /// Force refresh quote (ignores cache)
  Future<DailyQuote> refreshQuote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheDateKey);
    return getDailyQuote();
  }
}
