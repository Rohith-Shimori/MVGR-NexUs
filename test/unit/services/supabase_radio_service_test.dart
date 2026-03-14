import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/supabase_radio_service.dart';

void main() {
  group('RadioTrack Model', () {
    test('creates track with required fields', () {
      final track = RadioTrack(
        id: '1',
        title: 'Test Song',
        audioUrl: 'https://example.com/track.mp3',
        uploadedBy: 'user_1',
        createdAt: DateTime.now(),
      );

      expect(track.id, '1');
      expect(track.title, 'Test Song');
      expect(track.audioUrl, 'https://example.com/track.mp3');
      expect(track.uploadedBy, 'user_1');
    });

    test('creates track with optional fields', () {
      final track = RadioTrack(
        id: '1',
        title: 'Summer Vibes',
        artist: 'DJ Campus',
        album: 'MVGR Hits',
        genre: 'Electronic',
        durationSeconds: 180,
        audioUrl: 'https://example.com/track.mp3',
        coverUrl: 'https://example.com/cover.jpg',
        uploadedBy: 'user_1',
        uploaderName: 'DJ Campus',
        createdAt: DateTime.now(),
      );

      expect(track.artist, 'DJ Campus');
      expect(track.album, 'MVGR Hits');
      expect(track.genre, 'Electronic');
      expect(track.durationSeconds, 180);
      expect(track.coverUrl, 'https://example.com/cover.jpg');
      expect(track.uploaderName, 'DJ Campus');
    });

    test('track with engagement metrics', () {
      final track = RadioTrack(
        id: '1',
        title: 'Popular Track',
        audioUrl: 'url',
        uploadedBy: 'user_1',
        playCount: 500,
        likesCount: 100,
        createdAt: DateTime.now(),
      );

      expect(track.playCount, 500);
      expect(track.likesCount, 100);
    });

    test('unapproved track', () {
      final track = RadioTrack(
        id: '1',
        title: 'Pending Approval',
        audioUrl: 'url',
        uploadedBy: 'user_1',
        isApproved: false,
        createdAt: DateTime.now(),
      );

      expect(track.isApproved, false);
    });

    test('default values for optional metrics', () {
      final track = RadioTrack(
        id: '1',
        title: 'New Track',
        audioUrl: 'url',
        uploadedBy: 'user_1',
        createdAt: DateTime.now(),
      );

      expect(track.playCount, 0);
      expect(track.likesCount, 0);
      expect(track.isApproved, true);
    });
  });

  group('RadioTrack Filtering', () {
    late List<RadioTrack> testTracks;

    setUp(() {
      testTracks = [
        RadioTrack(
          id: '1',
          title: 'Rock Song',
          artist: 'Artist 1',
          genre: 'Rock',
          audioUrl: 'url1',
          uploadedBy: 'user_1',
          playCount: 100,
          isApproved: true,
          createdAt: DateTime.now(),
        ),
        RadioTrack(
          id: '2',
          title: 'Pop Song',
          artist: 'Artist 2',
          genre: 'Pop',
          audioUrl: 'url2',
          uploadedBy: 'user_2',
          playCount: 500,
          isApproved: true,
          createdAt: DateTime.now(),
        ),
        RadioTrack(
          id: '3',
          title: 'Pending Song',
          artist: 'Artist 3',
          genre: 'Jazz',
          audioUrl: 'url3',
          uploadedBy: 'user_1',
          playCount: 0,
          isApproved: false,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('filter by genre', () {
      final rockTracks = testTracks.where((t) => t.genre == 'Rock').toList();
      expect(rockTracks.length, 1);
      expect(rockTracks.first.id, '1');
    });

    test('filter approved tracks', () {
      final approved = testTracks.where((t) => t.isApproved).toList();
      expect(approved.length, 2);
    });

    test('filter by uploader', () {
      final user1Tracks = testTracks.where((t) => t.uploadedBy == 'user_1').toList();
      expect(user1Tracks.length, 2);
    });

    test('sort by play count (most popular)', () {
      final sorted = List<RadioTrack>.from(testTracks)
        ..sort((a, b) => b.playCount.compareTo(a.playCount));
      expect(sorted.first.id, '2');
      expect(sorted.first.playCount, 500);
    });
  });

  group('RadioTrack Search', () {
    late List<RadioTrack> testTracks;

    setUp(() {
      testTracks = [
        RadioTrack(
          id: '1',
          title: 'Summer Night Jazz',
          artist: 'Jazz Band',
          genre: 'Jazz',
          audioUrl: 'url1',
          uploadedBy: 'user_1',
          createdAt: DateTime.now(),
        ),
        RadioTrack(
          id: '2',
          title: 'Campus Anthem',
          artist: 'Student Choir',
          album: 'College Days',
          genre: 'Pop',
          audioUrl: 'url2',
          uploadedBy: 'user_2',
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('search by title', () {
      final query = 'jazz';
      final results = testTracks
          .where((t) => t.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('search by artist', () {
      final query = 'choir';
      final results = testTracks
          .where((t) => t.artist?.toLowerCase().contains(query.toLowerCase()) ?? false)
          .toList();
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('search by album', () {
      final query = 'College';
      final results = testTracks
          .where((t) => t.album?.toLowerCase().contains(query.toLowerCase()) ?? false)
          .toList();
      expect(results.length, 1);
    });
  });

  group('RadioTrack Validation', () {
    test('track duration formatting', () {
      final track = RadioTrack(
        id: '1',
        title: 'Test',
        audioUrl: 'url',
        uploadedBy: 'user',
        durationSeconds: 185, // 3:05
        createdAt: DateTime.now(),
      );

      // Simulate formatting (3 minutes 5 seconds)
      final minutes = track.durationSeconds! ~/ 60;
      final seconds = track.durationSeconds! % 60;
      final formatted = '$minutes:${seconds.toString().padLeft(2, '0')}';
      
      expect(formatted, '3:05');
    });

    test('null duration handling', () {
      final track = RadioTrack(
        id: '1',
        title: 'Test',
        audioUrl: 'url',
        uploadedBy: 'user',
        createdAt: DateTime.now(),
      );

    });
  });

  group('SupabaseRadioService Operations', () {
    late SupabaseRadioService service;

    setUp(() {
      service = SupabaseRadioService();
      // Initialize with some data for testing logic
      service.tracks.clear();
    });

    test('uploadTrack adds track and updates state', () async {
      final success = await service.uploadTrack(
        title: 'New Track',
        audioUrl: 'url',
        uploadedBy: 'user1',
      );
      
      // Note: In real test, fetchTracks() would be called which would 
      // fetch from mock. Here we just verify the service call completes.
      expect(success, isTrue);
    });

    test('updateTrack returns true on success', () async {
      final success = await service.updateTrack(
        trackId: '1',
        title: 'Updated Title',
      );
      expect(success, isTrue);
    });

    test('deleteTrack removes track from local list', () async {
      final track = RadioTrack(
        id: '99',
        title: 'Delete Me',
        audioUrl: 'url',
        uploadedBy: 'user',
        createdAt: DateTime.now(),
      );
      service.tracks.add(track);
      
      final success = await service.deleteTrack('99');
      expect(success, isTrue);
      expect(service.tracks.any((t) => t.id == '99'), isFalse);
    });
    
    test('toggleLike updates local set', () async {
      const trackId = 'track123';
      const userId = 'user456';
      
      final success = await service.toggleLike(trackId, userId);
      expect(success, isTrue);
      expect(service.likedTrackIds.contains(trackId), isTrue);
      
      await service.toggleLike(trackId, userId);
      expect(service.likedTrackIds.contains(trackId), isFalse);
    });
  });
}
