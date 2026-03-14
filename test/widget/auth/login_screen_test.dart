import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mvgr_nexus/features/auth/screens/login_screen.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';
import 'package:mvgr_nexus/core/errors/result.dart'; // Import Result for dummy value
import 'package:mvgr_nexus/domain/entities/user.dart'; // Import User entity

import '../../helpers/test_helper.mocks.dart';

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    provideDummy(Result<void>.success(null)); // Needed if AuthProvider uses Result<void> methods
    provideDummy(Result<User>.success(User(
      id: 'dummy',
      email: 'dummy@test.com',
      name: 'Dummy',
      createdAt: DateTime.now(),
    ))); // Needed for signIn return type

    // Stub properties to avoid NPEs during build
    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.errorMessage).thenReturn(null);
    when(mockAuthProvider.isAuthenticated).thenReturn(false);
    
    // Stub addListener/removeListener to avoid errors from Provider
    when(mockAuthProvider.addListener(any)).thenReturn(null);
    when(mockAuthProvider.removeListener(any)).thenReturn(null);
    when(mockAuthProvider.hasListeners).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
    expect(find.text('Login'), findsOneWidget); // Button text
    expect(find.byKey(const Key('login_button')), findsOneWidget);
  });

  testWidgets('Tapping Login with valid input calls signIn', (WidgetTester tester) async {
    // Arrange
    final tUser = User(
      id: '1', 
      email: 'test@example.com', 
      name: 'Test User', 
      role: UserRole.student,
      department: 'CSE', 
      year: 1, 
      createdAt: DateTime.now(),
    );
    
    when(mockAuthProvider.signIn(
      email: anyNamed('email'), 
      password: anyNamed('password')
    )).thenAnswer((_) async => Result.success(tUser));

    await tester.pumpWidget(createWidgetUnderTest());

    // Act - Enter email and password using correct key finders
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');

    // Tap Login button
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump(); // Start future
    
    // Assert
    verify(mockAuthProvider.signIn(
      email: 'test@example.com',
      password: 'password123',
    )).called(1);
  });
}
