import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user favorites locally
/// Supports clubs, events, and any string-based ID favorites
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._();
  static FavoritesService get instance => _instance;
  FavoritesService._();

  SharedPreferences? _prefs;
  
  // In-memory cache for fast access
  final Set<String> _favoriteClubs = {};
  final Set<String> _favoriteEvents = {};
  final Set<String> _recentSearches = {};

  static const String _clubsKey = 'favorite_clubs';
  static const String _eventsKey = 'favorite_events';
  static const String _searchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  /// Initialize the service - call once at app startup
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoriteClubs.addAll(_prefs?.getStringList(_clubsKey) ?? []);
    _favoriteEvents.addAll(_prefs?.getStringList(_eventsKey) ?? []);
    _recentSearches.addAll(_prefs?.getStringList(_searchesKey) ?? []);
  }

  // ============ CLUBS ============
  
  bool isClubFavorite(String clubId) => _favoriteClubs.contains(clubId);
  
  List<String> get favoriteClubIds => _favoriteClubs.toList();
  
  void toggleClubFavorite(String clubId) {
    if (_favoriteClubs.contains(clubId)) {
      _favoriteClubs.remove(clubId);
    } else {
      _favoriteClubs.add(clubId);
    }
    _saveFavorites(_clubsKey, _favoriteClubs);
    notifyListeners();
  }

  // ============ EVENTS ============
  
  bool isEventFavorite(String eventId) => _favoriteEvents.contains(eventId);
  
  List<String> get favoriteEventIds => _favoriteEvents.toList();
  
  void toggleEventFavorite(String eventId) {
    if (_favoriteEvents.contains(eventId)) {
      _favoriteEvents.remove(eventId);
    } else {
      _favoriteEvents.add(eventId);
    }
    _saveFavorites(_eventsKey, _favoriteEvents);
    notifyListeners();
  }

  // ============ RECENT SEARCHES ============
  
  List<String> get recentSearches => _recentSearches.toList().reversed.toList();
  
  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    _recentSearches.remove(query); // Remove if exists (to move to end)
    _recentSearches.add(query);
    // Keep only last N searches
    while (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.remove(_recentSearches.first);
    }
    _saveFavorites(_searchesKey, _recentSearches);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    _prefs?.remove(_searchesKey);
    notifyListeners();
  }

  // ============ HELPERS ============
  
  void _saveFavorites(String key, Set<String> data) {
    _prefs?.setStringList(key, data.toList());
  }

  /// Generic favorite check - useful for extension
  bool isFavorite(String type, String id) {
    switch (type) {
      case 'club': return isClubFavorite(id);
      case 'event': return isEventFavorite(id);
      default: return false;
    }
  }

  /// Generic toggle - useful for extension  
  void toggleFavorite(String type, String id) {
    switch (type) {
      case 'club': toggleClubFavorite(id);
      case 'event': toggleEventFavorite(id);
    }
  }
}

/// Global instance
final favoritesService = FavoritesService.instance;
