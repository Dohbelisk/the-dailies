import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Audio service for managing sound effects, music, and vibration
///
/// Sound files should be placed in assets/sounds/:
/// - tap.mp3          - Button/cell tap sound
/// - success.mp3      - Correct answer sound
/// - error.mp3        - Wrong answer sound
/// - complete.mp3     - Puzzle completion fanfare
/// - word_found.mp3   - Word search word found
/// - hint.mp3         - Hint used sound
/// - background.mp3   - Background music (looping)
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio players
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  // Settings keys
  static const String _soundEnabledKey = 'audio_sound_enabled';
  static const String _musicEnabledKey = 'audio_music_enabled';
  static const String _vibrationEnabledKey = 'audio_vibration_enabled';
  static const String _masterVolumeKey = 'audio_master_volume';
  static const String _effectsVolumeKey = 'audio_effects_volume';
  static const String _musicVolumeKey = 'audio_music_volume';

  // State
  bool _isInitialized = false;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  double _masterVolume = 0.8;
  double _effectsVolume = 0.8;
  double _musicVolume = 0.5;

  // Track if music is currently playing
  bool _isMusicPlaying = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get masterVolume => _masterVolume;
  double get effectsVolume => _effectsVolume;
  double get musicVolume => _musicVolume;

  // Computed volumes
  double get _effectiveEffectsVolume => _masterVolume * _effectsVolume;
  double get _effectiveMusicVolume => _masterVolume * _musicVolume;

  /// Initialize the audio service and load saved settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
      _masterVolume = prefs.getDouble(_masterVolumeKey) ?? 0.8;
      _effectsVolume = prefs.getDouble(_effectsVolumeKey) ?? 0.8;
      _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.5;

      // Configure audio players
      await _effectPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);

      _isInitialized = true;
      print('AudioService initialized');
    } catch (e) {
      print('AudioService initialization error: $e');
    }
  }

  // ==================== SETTINGS ====================

  /// Toggle sound effects on/off
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
  }

  /// Toggle music on/off
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled && _isMusicPlaying) {
      await stopMusic();
    }
    await _saveSettings();
  }

  /// Toggle vibration on/off
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveSettings();
  }

  /// Set master volume (0.0 - 1.0)
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    await _updateVolumes();
    await _saveSettings();
  }

  /// Set effects volume (0.0 - 1.0)
  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
  }

  /// Set music volume (0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _updateVolumes();
    await _saveSettings();
  }

  Future<void> _updateVolumes() async {
    if (_isMusicPlaying) {
      await _musicPlayer.setVolume(_effectiveMusicVolume);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, _soundEnabled);
    await prefs.setBool(_musicEnabledKey, _musicEnabled);
    await prefs.setBool(_vibrationEnabledKey, _vibrationEnabled);
    await prefs.setDouble(_masterVolumeKey, _masterVolume);
    await prefs.setDouble(_effectsVolumeKey, _effectsVolume);
    await prefs.setDouble(_musicVolumeKey, _musicVolume);
  }

  // ==================== SOUND EFFECTS ====================

  /// Play a sound effect
  Future<void> _playEffect(String assetPath) async {
    if (!_soundEnabled || _effectiveEffectsVolume == 0) return;

    try {
      await _effectPlayer.setVolume(_effectiveEffectsVolume);
      await _effectPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Sound file might not exist, fail silently
      print('Could not play sound: $assetPath - $e');
    }
  }

  /// Play tap/click sound
  Future<void> playTap() async {
    await _playEffect('sounds/tap.mp3');
    await vibrate(duration: 10);
  }

  /// Play success sound (correct answer)
  Future<void> playSuccess() async {
    await _playEffect('sounds/success.mp3');
    await vibrate(duration: 50);
  }

  /// Play error sound (wrong answer)
  Future<void> playError() async {
    await _playEffect('sounds/error.mp3');
    await vibrate(duration: 300, pattern: [0, 100, 50, 100, 50, 100]);
  }

  /// Play puzzle completion fanfare
  Future<void> playComplete() async {
    await _playEffect('sounds/complete.mp3');
    await vibrate(duration: 200, pattern: [0, 100, 50, 100, 50, 100]);
  }

  /// Play word found sound (word search)
  Future<void> playWordFound() async {
    await _playEffect('sounds/word_found.mp3');
    await vibrate(duration: 30);
  }

  /// Play hint sound
  Future<void> playHint() async {
    await _playEffect('sounds/hint.mp3');
    await vibrate(duration: 20);
  }

  /// Play number placed sound
  Future<void> playNumberPlaced() async {
    await _playEffect('sounds/tap.mp3');
    await vibrate(duration: 15);
  }

  /// Play note toggled sound
  Future<void> playNoteToggle() async {
    await _playEffect('sounds/tap.mp3');
  }

  // ==================== MUSIC ====================

  /// Start background music
  Future<void> startMusic() async {
    if (!_musicEnabled || _isMusicPlaying) return;

    try {
      await _musicPlayer.setVolume(_effectiveMusicVolume);
      await _musicPlayer.play(AssetSource('sounds/background.mp3'));
      _isMusicPlaying = true;
    } catch (e) {
      print('Could not start music: $e');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    if (!_isMusicPlaying) return;

    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
    } catch (e) {
      print('Could not stop music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    if (!_isMusicPlaying) return;

    try {
      await _musicPlayer.pause();
    } catch (e) {
      print('Could not pause music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (!_musicEnabled || !_isMusicPlaying) return;

    try {
      await _musicPlayer.resume();
    } catch (e) {
      print('Could not resume music: $e');
    }
  }

  // ==================== VIBRATION ====================

  /// Trigger haptic feedback
  Future<void> vibrate({int duration = 50, List<int>? pattern}) async {
    if (!_vibrationEnabled) return;

    try {
      if (pattern != null) {
        // Pattern vibration not easily supported, use simple feedback
        await HapticFeedback.mediumImpact();
      } else if (duration <= 20) {
        await HapticFeedback.lightImpact();
      } else if (duration <= 50) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      print('Vibration error: $e');
    }
  }

  /// Light haptic feedback (for taps)
  Future<void> lightHaptic() async {
    if (!_vibrationEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback (for selections)
  Future<void> mediumHaptic() async {
    if (!_vibrationEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback (for errors, completion)
  Future<void> heavyHaptic() async {
    if (!_vibrationEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click haptic
  Future<void> selectionClick() async {
    if (!_vibrationEnabled) return;
    await HapticFeedback.selectionClick();
  }

  // ==================== CLEANUP ====================

  /// Dispose of audio players
  void dispose() {
    _effectPlayer.dispose();
    _musicPlayer.dispose();
  }
}
