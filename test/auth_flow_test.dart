import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abaarso_car_rental/features/auth/domain/user_entity.dart';
import 'package:abaarso_car_rental/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Should successfully register a new user using Simulated DataSource', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // Verify initial state is unauthenticated
      expect(container.read(authNotifierProvider).user, null);
      expect(container.read(authNotifierProvider).isLoading, false);

      // Trigger Sign Up
      await authNotifier.signUpWithEmail(
        email: 'testuser@abaarso.com',
        password: 'password123',
        fullName: 'Test User',
        role: UserRole.customer,
      );

      final state = container.read(authNotifierProvider);

      // Verify that registration succeeded and Firestore document details were seeded
      expect(state.isLoading, false);
      expect(state.errorMessageEn, null);
      expect(state.user, isNotNull);
      expect(state.user!.fullName, 'Test User');
      expect(state.user!.email, 'testuser@abaarso.com');
      expect(state.user!.role, UserRole.customer);
      expect(state.user!.isVerified, false);
    });

    test('Should fail to register a user with an already existing email address', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // Register the first user
      await authNotifier.signUpWithEmail(
        email: 'duplicate@abaarso.com',
        password: 'password123',
        fullName: 'Original User',
        role: UserRole.customer,
      );

      // Confirm first user registered successfully
      expect(container.read(authNotifierProvider).user!.fullName, 'Original User');

      // Logout to simulate second registration
      await authNotifier.logout();
      expect(container.read(authNotifierProvider).user, null);

      // Attempt to register a second user with the same email
      await authNotifier.signUpWithEmail(
        email: 'duplicate@abaarso.com',
        password: 'password345',
        fullName: 'Imposter User',
        role: UserRole.customer,
      );

      final state = container.read(authNotifierProvider);

      // Verify registration failed with duplicate email warning
      expect(state.isLoading, false);
      expect(state.user, null);
      expect(state.errorMessageEn, 'An account already exists with this email address.');
    });

    test('Should login successfully with simulated user after account creation', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // Register the new user
      await authNotifier.signUpWithEmail(
        email: 'loginflow@abaarso.com',
        password: 'securepassword',
        fullName: 'Login Flow User',
        role: UserRole.customer,
      );

      // Verify successful registration
      expect(container.read(authNotifierProvider).user!.fullName, 'Login Flow User');

      // Logout the user
      await authNotifier.logout();
      expect(container.read(authNotifierProvider).user, null);

      // Sign back in with the created credentials
      await authNotifier.signInWithEmail(
        email: 'loginflow@abaarso.com',
        password: 'securepassword',
      );

      final state = container.read(authNotifierProvider);

      // Verify successful login works after account creation
      expect(state.isLoading, false);
      expect(state.errorMessageEn, null);
      expect(state.user, isNotNull);
      expect(state.user!.fullName, 'Login Flow User');
      expect(state.user!.email, 'loginflow@abaarso.com');
    });

    test('Should successfully register and login an Admin user with auto-verification', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // Sign up with an email containing 'admin'
      await authNotifier.signUpWithEmail(
        email: 'mytestadmin@abaarso.com',
        password: 'adminpassword',
        fullName: 'Admin User',
        role: UserRole.admin,
      );

      var state = container.read(authNotifierProvider);

      // Verify admin details are saved correctly and role is Admin with auto-verification
      expect(state.isLoading, false);
      expect(state.errorMessageEn, null);
      expect(state.user, isNotNull);
      expect(state.user!.role, UserRole.admin);
      expect(state.user!.isVerified, true); // Admin must be auto-verified!

      // Logout the admin
      await authNotifier.logout();
      expect(container.read(authNotifierProvider).user, null);

      // Login as the created Admin
      await authNotifier.signInWithEmail(
        email: 'mytestadmin@abaarso.com',
        password: 'adminpassword',
      );

      state = container.read(authNotifierProvider);

      // Verify successful login as Admin
      expect(state.isLoading, false);
      expect(state.errorMessageEn, null);
      expect(state.user, isNotNull);
      expect(state.user!.role, UserRole.admin);
      expect(state.user!.isVerified, true);
    });
  });
}
