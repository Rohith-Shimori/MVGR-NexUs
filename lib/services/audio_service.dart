/// Audio Service for Radio Playback
/// Handles high quality audio playback for the campus radio feature
library;

import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:just_audio/just_audio.dart';

/// Audio track for the radio
class AudioTrack {
  final String id;
  final String name;
  final String artistName;
  final String assetPath;
  
  const AudioTrack({
    required this.id,
    required this.name,
    required this.artistName,
    required this.assetPath,
  });
}
/// Audio service uses Supabase tracks via playFromUrl() method\r\n
/// Audio service for playing radio tracks
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._();
  static AudioService get instance => _instance;
  AudioService._();
  
  final AudioPlayer _player = AudioPlayer();
  AudioTrack? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  // Getters
  AudioTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inSeconds > 0 
      ? _position.inSeconds / _duration.inSeconds 
      : 0.0;
  
  /// Initialize audio service
  Future<void> initialize() async {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    
    // Listen to position changes
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    
    // Listen to duration changes
    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    
    AppLogger.info(' Audio service initialized');
  }
  
  /// Play a track from assets
  Future<void> playTrack(AudioTrack track) async {
    try {
      _currentTrack = track;
      notifyListeners();
      
      await _player.setAsset(track.assetPath);
      await _player.play();
      
      AppLogger.info(' Playing: ${track.name}');
    } catch (e) {
      AppLogger.error(' Error playing track: $e');
    }
  }
  
  /// Play a track from URL (for Supabase tracks)
  Future<void> playFromUrl(String url, {String? title, String? artist}) async {
    try {
      // Create a temporary track for URL-based playback
      _currentTrack = AudioTrack(
        id: url.hashCode.toString(),
        name: title ?? 'Unknown Track',
        artistName: artist ?? 'Unknown Artist',
        assetPath: url,
      );
      notifyListeners();
      
      await _player.setUrl(url);
      await _player.play();
      
      AppLogger.info(' Playing from URL: ${_currentTrack?.name}');
    } catch (e) {
      AppLogger.error(' Error playing from URL: $e');
    }
  }
  
  /// Get current track title
  String? get currentTrackTitle => _currentTrack?.name;
  
  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }
  
  /// Resume playback
  Future<void> resume() async {
    await _player.play();
  }
  
  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _currentTrack = null;
    _position = Duration.zero;
    notifyListeners();
  }
  
  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }
  
  /// Dispose resources
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// Singleton instance
final audioService = AudioService.instance;
