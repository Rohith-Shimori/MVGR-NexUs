import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

/// Mock user service for development before auth is implemented
/// Will be replaced with FirebaseAuth integration later
class MockUserService {
  static AppUser? _currentUser;
  static final List<AppUser> _testUsers = [
    AppUser.testStudent(),
    AppUser.testStudent(name: 'Club Admin', role: UserRole.clubAdmin).copyWith(
      uid: 'club_admin_001',
      email: 'clubadmin@mvgrce.edu.in',
    ),
    AppUser.testStudent(name: 'Council Member', role: UserRole.council).copyWith(
      uid: 'council_001',
      email: 'council@mvgrce.edu.in',
    ),
    AppUser.testStudent(name: 'Faculty Member', role: UserRole.faculty).copyWith(
      uid: 'faculty_001',
      email: 'faculty@mvgrce.edu.in',
      department: 'Computer Science',
    ),
  ];

  /// Get current mock user
  static AppUser get currentUser => _currentUser ?? _testUsers[0];

  /// Set current user for testing different roles
  static void setCurrentUser(AppUser user) {
    _currentUser = user;
  }

  /// Login as different role for testing
  static void loginAsStudent() {
    _currentUser = _testUsers[0];
  }

  static void loginAsClubAdmin() {
    _currentUser = _testUsers[1];
  }

  static void loginAsCouncil() {
    _currentUser = _testUsers[2];
  }

  static void loginAsFaculty() {
    _currentUser = _testUsers[3];
  }

  /// Check if user has permission
  static bool canModerate() => currentUser.role.canModerate;
  static bool canCreateClub() => currentUser.role.canCreateClub;
  static bool canCreateEvent() => currentUser.role.canCreateEvent;
  static bool canApproveContent() => currentUser.role.canApproveContent;

  /// Get all test users
  static List<AppUser> get allUsers => _testUsers;

  /// Get user by ID
  static AppUser? getUserById(String id) {
    try {
      return _testUsers.firstWhere((u) => u.uid == id);
    } catch (_) {
      return null;
    }
  }

  /// Update current user's interests
  static void updateInterests(List<String> interests) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(interests: interests);
    } else {
      _currentUser = _testUsers[0].copyWith(interests: interests);
    }
  }

  /// Update current user's profile
  static void updateProfile({
    String? bio,
    String? profilePhotoUrl,
    String? backgroundType,
    int? backgroundColorValue,
    String? backgroundImageUrl,
  }) {
    final current = _currentUser ?? _testUsers[0];
    _currentUser = current.copyWith(
      bio: bio ?? current.bio,
      profilePhotoUrl: profilePhotoUrl ?? current.profilePhotoUrl,
      backgroundType: backgroundType ?? current.backgroundType,
      backgroundColorValue: backgroundColorValue ?? current.backgroundColorValue,
      backgroundImageUrl: backgroundImageUrl ?? current.backgroundImageUrl,
    );
  }
}

/// Main user provider - will switch to Firebase later
class UserProvider {
  /// Currently uses mock service - will be replaced with Firebase Auth
  AppUser get currentUser => MockUserService.currentUser;
  
  bool get isLoggedIn => true; // Always true for testing
  
  String get userId => currentUser.uid;
  String get userName => currentUser.name;
  UserRole get userRole => currentUser.role;
  
  bool get canModerate => currentUser.role.canModerate;
  bool get canCreateClub => currentUser.role.canCreateClub;
  bool get canCreateEvent => currentUser.role.canCreateEvent;
}
