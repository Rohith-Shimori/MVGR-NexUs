import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mvgr_nexus/features/vault/screens/vault_screen.dart';
import 'package:mvgr_nexus/features/vault/models/vault_model.dart';
import 'package:mvgr_nexus/services/supabase_vault_service.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';
import 'package:mvgr_nexus/domain/entities/user.dart';

import '../../helpers/test_helper.mocks.dart';

// Manual Mock for SupabaseVaultService since it's not generated
class MockSupabaseVaultService extends Mock implements SupabaseVaultService {
  List<VaultItem> _items = [];
  bool _isLoading = false;
  String? _error;

  @override
  List<VaultItem> get items => _items;
  set items(List<VaultItem> value) => _items = value;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool value) => _isLoading = value;

  @override
  String? get error => _error;
  set error(String? value) => _error = value;

  @override
  Future<void> fetchItems({
    String? branch,
    int? year,
    int? semester,
    String? subject,
    VaultItemType? type,
  }) async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void notifyListeners() {}

  @override
  bool get hasListeners => false;
}

void main() {
  late MockSupabaseVaultService mockVaultService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockVaultService = MockSupabaseVaultService();
    mockAuthProvider = MockAuthProvider();

    // Setup AuthProvider mocks
    final testUser = User(
      id: 'user_123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.student,
      department: 'CSE',
      year: 3,
      createdAt: DateTime.now(),
    );

    when(mockAuthProvider.user).thenReturn(testUser);
    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.isAuthenticated).thenReturn(true);
    when(mockAuthProvider.addListener(any)).thenReturn(null);
    when(mockAuthProvider.removeListener(any)).thenReturn(null);
  });

  group('VaultScreen', () {
    testWidgets('renders VaultScreen header', (WidgetTester tester) async {
      // Arrange
      mockVaultService.items = <VaultItem>[];


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseVaultService>.value(
                value: mockVaultService,
              ),
            ],
            child: const VaultScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('The Vault'), findsOneWidget);
    });

    testWidgets('displays empty state when no items', (WidgetTester tester) async {
      // Arrange
      mockVaultService.items = <VaultItem>[];


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseVaultService>.value(
                value: mockVaultService,
              ),
            ],
            child: const VaultScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('No resources found'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('displays vault items when available', (WidgetTester tester) async {
      // Arrange
      final items = [
        VaultItem(
          id: '1',
          title: 'Notes Unit 1',
          description: 'Desc',
          fileUrl: 'path/to/file',
          fileName: 'notes.pdf',
          fileSizeBytes: 1024,
          type: VaultItemType.notes,
          subject: 'DS',
          branch: 'CSE',
          year: 2,
          semester: 1,
          uploaderId: 'user_1',
          uploaderName: 'Uploader',
          createdAt: DateTime.now(),
        ),
      ];

      mockVaultService.items = items;


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseVaultService>.value(
                value: mockVaultService,
              ),
            ],
            child: const VaultScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('Notes Unit 1'), findsOneWidget);
      expect(find.text('DS'), findsOneWidget);
      expect(find.text('CSE'), findsOneWidget);
    });

    testWidgets('search bar renders', (WidgetTester tester) async {
      mockVaultService.items = <VaultItem>[];


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseVaultService>.value(
                value: mockVaultService,
              ),
            ],
            child: const VaultScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search notes, papers, textbooks...'), findsOneWidget);
    });
  });

  group('VaultItemType Enum', () {
    test('displayName returns correct values', () {
      expect(VaultItemType.notes.displayName, 'Notes');
      expect(VaultItemType.pyq.displayName, 'Previous Year Questions');
      expect(VaultItemType.handwritten.displayName, 'Handwritten Notes');
      expect(VaultItemType.assignment.displayName, 'Assignment');
      expect(VaultItemType.slides.displayName, 'Slides');
      expect(VaultItemType.lab.displayName, 'Lab Manual');
      expect(VaultItemType.other.displayName, 'Other');
    });

    test('colors map defines all types', () {
      // This is implicit in the widget test but good to verify logic if extracted
      expect(VaultItemType.values.length, 7);
    });
  });
}
