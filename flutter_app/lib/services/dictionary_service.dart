import 'package:flutter/services.dart';

/// Service for loading and querying the word dictionary
class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  Set<String> _words = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  int get wordCount => _words.length;

  /// Load the dictionary from assets
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final data = await rootBundle.loadString('assets/data/words.txt');
      _words = data
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.length >= 4)
          .toSet();
      _isLoaded = true;
      print('DictionaryService: Loaded ${_words.length} words');
    } catch (e) {
      print('DictionaryService: Error loading dictionary: $e');
      _words = {};
      _isLoaded = false;
    }
  }

  /// Check if a word is valid
  bool isValidWord(String word) {
    return _words.contains(word.toUpperCase());
  }

  /// Find all valid words that can be formed from the given letters
  /// and must contain the center letter
  List<String> findValidWords(List<String> letters, String centerLetter) {
    final letterSet = letters.map((l) => l.toUpperCase()).toSet();
    final center = centerLetter.toUpperCase();

    return _words.where((word) {
      // Must contain center letter
      if (!word.contains(center)) return false;

      // All letters in word must be from our letter set
      for (final char in word.split('')) {
        if (!letterSet.contains(char)) return false;
      }

      return true;
    }).toList()
      ..sort();
  }

  /// Find pangrams (words using all 7 letters)
  List<String> findPangrams(List<String> letters, String centerLetter) {
    final letterSet = letters.map((l) => l.toUpperCase()).toSet();
    final center = centerLetter.toUpperCase();

    return _words.where((word) {
      // Must contain center letter
      if (!word.contains(center)) return false;

      // Check if word uses all 7 letters
      final wordLetters = word.split('').toSet();

      // All letters in word must be from our letter set
      for (final char in wordLetters) {
        if (!letterSet.contains(char)) return false;
      }

      // Must use all 7 letters
      return wordLetters.length == 7 &&
             letterSet.every((l) => word.contains(l));
    }).toList()
      ..sort();
  }

  /// Get two-letter combinations and their word counts for hints
  Map<String, int> getTwoLetterHints(
    List<String> letters,
    String centerLetter,
    Set<String> foundWords,
  ) {
    final validWords = findValidWords(letters, centerLetter);
    final unfoundWords = validWords
        .where((w) => !foundWords.contains(w.toUpperCase()))
        .toList();

    final Map<String, int> hints = {};
    for (final word in unfoundWords) {
      if (word.length >= 2) {
        final twoLetter = word.substring(0, 2);
        hints[twoLetter] = (hints[twoLetter] ?? 0) + 1;
      }
    }

    return Map.fromEntries(
      hints.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Get a hint for an unfound word (returns first letter and length)
  Map<String, dynamic>? getWordHint(
    List<String> letters,
    String centerLetter,
    Set<String> foundWords,
  ) {
    final validWords = findValidWords(letters, centerLetter);
    final unfoundWords = validWords
        .where((w) => !foundWords.contains(w.toUpperCase()))
        .toList();

    if (unfoundWords.isEmpty) return null;

    // Pick a random unfound word
    unfoundWords.shuffle();
    final word = unfoundWords.first;

    return {
      'firstLetter': word[0],
      'length': word.length,
      'word': word, // For reveal hint
    };
  }

  /// Get pangram hint (first letter and length of an unfound pangram)
  Map<String, dynamic>? getPangramHint(
    List<String> letters,
    String centerLetter,
    Set<String> foundWords,
  ) {
    final pangrams = findPangrams(letters, centerLetter);
    final unfoundPangrams = pangrams
        .where((w) => !foundWords.contains(w.toUpperCase()))
        .toList();

    if (unfoundPangrams.isEmpty) return null;

    // Pick a random unfound pangram
    unfoundPangrams.shuffle();
    final pangram = unfoundPangrams.first;

    return {
      'firstLetter': pangram[0],
      'length': pangram.length,
      'word': pangram, // For reveal
    };
  }
}
