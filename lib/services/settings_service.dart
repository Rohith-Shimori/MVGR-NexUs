import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}

/// Settings Service - Manages user preferences
/// Persists to SharedPreferences automatically
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;

  SettingsService._internal();

  // Track if we're currently loading to prevent save during load
  bool _isLoading = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    // Auto-save when settings change (but not during initial load)
    if (!_isLoading) {
      saveToStorage();
    }
  }

  // ============ NOTIFICATIONS ============
  bool _pushNotifications = true;
  bool _eventReminders = true;
  bool _clubUpdates = true;
  bool _announcements = true;
  bool _mentorshipUpdates = true;
  bool _forumReplies = true;

  bool get pushNotifications => _pushNotifications;
  set pushNotifications(bool value) {
    _pushNotifications = value;
    notifyListeners();
  }

  bool get eventReminders => _eventReminders;
  set eventReminders(bool value) {
    _eventReminders = value;
    notifyListeners();
  }

  bool get clubUpdates => _clubUpdates;
  set clubUpdates(bool value) {
    _clubUpdates = value;
    notifyListeners();
  }

  bool get announcements => _announcements;
  set announcements(bool value) {
    _announcements = value;
    notifyListeners();
  }

  bool get mentorshipUpdates => _mentorshipUpdates;
  set mentorshipUpdates(bool value) {
    _mentorshipUpdates = value;
    notifyListeners();
  }

  bool get forumReplies => _forumReplies;
  set forumReplies(bool value) {
    _forumReplies = value;
    notifyListeners();
  }

  // ============ APPEARANCE ============
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _enableAnimations = true;
  bool _hapticFeedback = true;
  bool _compactMode = false;

  AppThemeMode get themeMode => _themeMode;
  set themeMode(AppThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  bool get enableAnimations => _enableAnimations;
  set enableAnimations(bool value) {
    _enableAnimations = value;
    notifyListeners();
  }

  bool get hapticFeedback => _hapticFeedback;
  set hapticFeedback(bool value) {
    _hapticFeedback = value;
    notifyListeners();
  }

  bool get compactMode => _compactMode;
  set compactMode(bool value) {
    _compactMode = value;
    notifyListeners();
  }

  // ============ PRIVACY ============
  bool _profileVisible = true;
  bool _showActivityStatus = true;
  bool _analyticsEnabled = true;
  bool _showEmailToClubs = false;
  bool _showPhoneToMentors = false;

  bool get profileVisible => _profileVisible;
  set profileVisible(bool value) {
    _profileVisible = value;
    notifyListeners();
  }

  bool get showActivityStatus => _showActivityStatus;
  set showActivityStatus(bool value) {
    _showActivityStatus = value;
    notifyListeners();
  }

  bool get analyticsEnabled => _analyticsEnabled;
  set analyticsEnabled(bool value) {
    _analyticsEnabled = value;
    notifyListeners();
  }

  bool get showEmailToClubs => _showEmailToClubs;
  set showEmailToClubs(bool value) {
    _showEmailToClubs = value;
    notifyListeners();
  }

  bool get showPhoneToMentors => _showPhoneToMentors;
  set showPhoneToMentors(bool value) {
    _showPhoneToMentors = value;
    notifyListeners();
  }

  // ============ DATA & STORAGE ============
  double _cacheSize = 24.5; // MB

  double get cacheSize => _cacheSize;

  void clearCache() {
    _cacheSize = 0;
    notifyListeners();
  }

  // ============ CONTENT PREFERENCES ============
  bool _autoPlayVideos = true;
  bool _loadImagesOnData = true;
  String _defaultFeedView = 'all'; // 'all', 'clubs', 'events'

  bool get autoPlayVideos => _autoPlayVideos;
  set autoPlayVideos(bool value) {
    _autoPlayVideos = value;
    notifyListeners();
  }

  bool get loadImagesOnData => _loadImagesOnData;
  set loadImagesOnData(bool value) {
    _loadImagesOnData = value;
    notifyListeners();
  }

  String get defaultFeedView => _defaultFeedView;
  set defaultFeedView(String value) {
    _defaultFeedView = value;
    notifyListeners();
  }

  // ============ RESET ============
  void resetToDefaults() {
    // Notifications
    _pushNotifications = true;
    _eventReminders = true;
    _clubUpdates = true;
    _announcements = true;
    _mentorshipUpdates = true;
    _forumReplies = true;

    // Appearance
    _themeMode = AppThemeMode.system;
    _enableAnimations = true;
    _hapticFeedback = true;
    _compactMode = false;

    // Privacy
    _profileVisible = true;
    _showActivityStatus = true;
    _analyticsEnabled = true;
    _showEmailToClubs = false;
    _showPhoneToMentors = false;

    // Content
    _autoPlayVideos = true;
    _loadImagesOnData = true;
    _defaultFeedView = 'all';

    notifyListeners();
  }

  // ============ PERSISTENCE ============
  Future<void> loadFromStorage() async {
    _isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    
    // Notifications
    _pushNotifications = prefs.getBool('pushNotifications') ?? true;
    _eventReminders = prefs.getBool('eventReminders') ?? true;
    _clubUpdates = prefs.getBool('clubUpdates') ?? true;
    _announcements = prefs.getBool('announcements') ?? true;
    _mentorshipUpdates = prefs.getBool('mentorshipUpdates') ?? true;
    _forumReplies = prefs.getBool('forumReplies') ?? true;
    
    // Appearance
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = AppThemeMode.values[themeModeIndex.clamp(0, AppThemeMode.values.length - 1)];
    _enableAnimations = prefs.getBool('enableAnimations') ?? true;
    _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
    _compactMode = prefs.getBool('compactMode') ?? false;
    
    // Privacy
    _profileVisible = prefs.getBool('profileVisible') ?? true;
    _showActivityStatus = prefs.getBool('showActivityStatus') ?? true;
    _analyticsEnabled = prefs.getBool('analyticsEnabled') ?? true;
    _showEmailToClubs = prefs.getBool('showEmailToClubs') ?? false;
    _showPhoneToMentors = prefs.getBool('showPhoneToMentors') ?? false;
    
    // Content
    _autoPlayVideos = prefs.getBool('autoPlayVideos') ?? true;
    _loadImagesOnData = prefs.getBool('loadImagesOnData') ?? true;
    _defaultFeedView = prefs.getString('defaultFeedView') ?? 'all';
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Notifications
    await prefs.setBool('pushNotifications', _pushNotifications);
    await prefs.setBool('eventReminders', _eventReminders);
    await prefs.setBool('clubUpdates', _clubUpdates);
    await prefs.setBool('announcements', _announcements);
    await prefs.setBool('mentorshipUpdates', _mentorshipUpdates);
    await prefs.setBool('forumReplies', _forumReplies);
    
    // Appearance
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setBool('enableAnimations', _enableAnimations);
    await prefs.setBool('hapticFeedback', _hapticFeedback);
    await prefs.setBool('compactMode', _compactMode);
    
    // Privacy
    await prefs.setBool('profileVisible', _profileVisible);
    await prefs.setBool('showActivityStatus', _showActivityStatus);
    await prefs.setBool('analyticsEnabled', _analyticsEnabled);
    await prefs.setBool('showEmailToClubs', _showEmailToClubs);
    await prefs.setBool('showPhoneToMentors', _showPhoneToMentors);
    
    // Content
    await prefs.setBool('autoPlayVideos', _autoPlayVideos);
    await prefs.setBool('loadImagesOnData', _loadImagesOnData);
    await prefs.setString('defaultFeedView', _defaultFeedView);
  }
}

// Note: NotificationService, FeedbackService, and AnalyticsService were REMOVED
// from this file as they are duplicates of:
// - services/notification_service.dart (with Supabase Realtime)
// - services/supabase_feedback_service.dart (with Supabase persistence)
// - services/analytics_service.dart (with Supabase storage)
//
// Use those services instead via GetIt DI or the singleton instances.
