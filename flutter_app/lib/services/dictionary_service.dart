import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'firebase_service.dart';

/// Service for loading and querying the word dictionary
/// Supports syncing from backend for up-to-date word lists
class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  Set<String> _words = {};
  bool _isLoaded = false;
  String? _currentVersion;

  static const String _versionKey = 'dictionary_version';
  static const String _dictionaryFileName = 'dictionary.txt';

  bool get isLoaded => _isLoaded;
  int get wordCount => _words.length;
  String? get version => _currentVersion;

  /// Load the dictionary - tries synced version first, then bundled assets
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      // Try to load from cached sync file first
      final cachedWords = await _loadFromCache();
      if (cachedWords != null && cachedWords.isNotEmpty) {
        _words = cachedWords;
        _isLoaded = true;
        debugPrint('DictionaryService: Loaded ${_words.length} words from cache');
        return;
      }
    } catch (e) {
      debugPrint('DictionaryService: Cache load failed: $e');
    }

    // Fall back to bundled assets
    await _loadFromAssets();
  }

  /// Load dictionary from bundled assets
  Future<void> _loadFromAssets() async {
    try {
      final data = await rootBundle.loadString('assets/data/words.txt');
      _words = data
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.length >= 4 && w.isNotEmpty)
          .toSet();
      _isLoaded = true;
      debugPrint('DictionaryService: Loaded ${_words.length} words from assets');
    } catch (e) {
      debugPrint('DictionaryService: Error loading from assets: $e');
      _words = {};
      _isLoaded = false;
    }
  }

  /// Load dictionary from local cache
  Future<Set<String>?> _loadFromCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dictionaryFileName');

      if (!await file.exists()) {
        return null;
      }

      // Load version
      final prefs = await SharedPreferences.getInstance();
      _currentVersion = prefs.getString(_versionKey);

      final data = await file.readAsString();
      return data
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.length >= 4 && w.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('DictionaryService: Error loading from cache: $e');
      return null;
    }
  }

  /// Check for dictionary updates and sync if needed
  /// Call this after app startup to update in the background
  Future<bool> syncFromServer() async {
    try {
      final baseUrl = Environment.apiUrl;

      // Check server version
      final versionResponse = await http.get(
        Uri.parse('$baseUrl/dictionary/sync/version'),
      ).timeout(const Duration(seconds: 10));

      if (versionResponse.statusCode != 200) {
        debugPrint('DictionaryService: Failed to get server version');
        return false;
      }

      final versionData = versionResponse.body;
      final serverVersion = _parseVersion(versionData);

      if (serverVersion == null) {
        debugPrint('DictionaryService: Invalid version response');
        return false;
      }

      // Check if we need to update
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString(_versionKey);

      if (localVersion == serverVersion) {
        debugPrint('DictionaryService: Dictionary is up to date (v$serverVersion)');
        return false;
      }

      debugPrint('DictionaryService: Updating dictionary from $localVersion to $serverVersion');

      // Download new dictionary with ETag for caching
      final headers = <String, String>{};
      if (localVersion != null) {
        headers['If-None-Match'] = '"$localVersion"';
      }

      final wordsResponse = await http.get(
        Uri.parse('$baseUrl/dictionary/sync/words'),
        headers: headers,
      ).timeout(const Duration(seconds: 60));

      if (wordsResponse.statusCode == 304) {
        // Not modified, update local version anyway
        await prefs.setString(_versionKey, serverVersion);
        _currentVersion = serverVersion;
        debugPrint('DictionaryService: Dictionary not modified');
        return false;
      }

      if (wordsResponse.statusCode != 200) {
        debugPrint('DictionaryService: Failed to download dictionary: ${wordsResponse.statusCode}');
        return false;
      }

      // Save to cache
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dictionaryFileName');
      await file.writeAsString(wordsResponse.body);

      // Update version
      await prefs.setString(_versionKey, serverVersion);
      _currentVersion = serverVersion;

      // Reload into memory
      final newWords = wordsResponse.body
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.length >= 4 && w.isNotEmpty)
          .toSet();

      _words = newWords;
      _isLoaded = true;

      debugPrint('DictionaryService: Synced ${_words.length} words (v$serverVersion)');

      // Log to analytics
      FirebaseService().logAnalyticsEvent('dictionary_synced', parameters: {
        'word_count': _words.length,
        'version': serverVersion,
      });

      return true;
    } catch (e) {
      debugPrint('DictionaryService: Sync error: $e');
      FirebaseService().logError(e, StackTrace.current, reason: 'Dictionary sync failed');
      return false;
    }
  }

  /// Parse version from server response
  String? _parseVersion(String responseBody) {
    try {
      // Response is JSON: {"version":"abc123","wordCount":12345,"lastModified":"..."}
      final match = RegExp(r'"version"\s*:\s*"([^"]+)"').firstMatch(responseBody);
      return match?.group(1);
    } catch (e) {
      return null;
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

  /// Clear cached dictionary (for testing/debugging)
  Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dictionaryFileName');
      if (await file.exists()) {
        await file.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_versionKey);
      _currentVersion = null;
      debugPrint('DictionaryService: Cache cleared');
    } catch (e) {
      debugPrint('DictionaryService: Error clearing cache: $e');
    }
  }
}
