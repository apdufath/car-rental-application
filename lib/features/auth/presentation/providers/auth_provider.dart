import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_remote_datasource.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_entity.dart';

// State definition for Auth
class AuthState {
  final bool isLoading;
  final String? errorMessageEn;
  final String? errorMessageSo;
  final UserEntity? user;
  final String? verificationId;
  final bool codeSent;
  final bool needsRegistration;

  AuthState({
    this.isLoading = false,
    this.errorMessageEn,
    this.errorMessageSo,
    this.user,
    this.verificationId,
    this.codeSent = false,
    this.needsRegistration = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessageEn,
    String? errorMessageSo,
    UserEntity? user,
    String? verificationId,
    bool? codeSent,
    bool? needsRegistration,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessageEn: errorMessageEn,
      errorMessageSo: errorMessageSo,
      user: user ?? this.user,
      verificationId: verificationId ?? this.verificationId,
      codeSent: codeSent ?? this.codeSent,
      needsRegistration: needsRegistration ?? this.needsRegistration,
    );
  }
}

// 1. Remote DataSource Provider (supports failover simulation)
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  try {
    // If Firebase is initialized, return the standard data source
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuthRemoteDataSource();
    }
  } catch (_) {}
  // Default to Simulator for elegant local demonstration
  return SimulatedAuthRemoteDataSource();
});

// 2. Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepository(dataSource);
});

// 3. Auth State Changes Provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// 4. Custom User Data StreamProvider (dynamically tracks changes in firestore)
final userDataProvider = FutureProvider<UserEntity?>((ref) async {
  final authState = ref.watch(authStateChangesProvider).value;
  if (authState == null) return null;
  
  final repo = ref.watch(authRepositoryProvider);
  return await repo.fetchUserData(authState.uid);
});

// 5. Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        state = AuthState(user: null);
      } else {
        state = state.copyWith(isLoading: true);
        final userData = await _repository.fetchUserData(firebaseUser.uid);
        if (userData == null) {
          // Firebase authenticated but no custom Firestore user document exists
          state = AuthState(needsRegistration: true);
        } else {
          state = AuthState(user: userData);
        }
      }
    });
  }

  void clearErrors() {
    state = state.copyWith(errorMessageEn: null, errorMessageSo: null);
  }

  Future<void> sendVerificationCode(String phone) async {
    state = state.copyWith(isLoading: true, errorMessageEn: null, errorMessageSo: null);
    
    await _repository.sendOtp(
      phone: phone,
      onCodeSent: (verId) {
        state = state.copyWith(isLoading: false, verificationId: verId, codeSent: true);
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          errorMessageEn: err.messageEn,
          errorMessageSo: err.messageSo,
        );
      },
    );
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessageEn: null, errorMessageSo: null);
    try {
      final user = await _repository.signInWithEmail(email: email, password: password);
      if (user == null) {
        state = state.copyWith(isLoading: false, needsRegistration: true);
      } else {
        state = AuthState(user: user);
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: e.messageEn, errorMessageSo: e.messageSo);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessageEn: 'Sign in failed.',
        errorMessageSo: 'Galitaankii waa fashilantay.',
      );
    }
  }

  Future<void> verifyCode(String smsCode) async {
    final verId = state.verificationId;
    if (verId == null) return;

    state = state.copyWith(isLoading: true, errorMessageEn: null, errorMessageSo: null);
    try {
      final user = await _repository.verifyOtpAndFetchUser(verificationId: verId, smsCode: smsCode);
      if (user == null) {
        // Logged in successfully but needs to complete registration
        state = state.copyWith(isLoading: false, needsRegistration: true);
      } else {
        state = AuthState(user: user);
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: e.messageEn, errorMessageSo: e.messageSo);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessageEn: 'Verification failed.',
        errorMessageSo: 'Xaqiijintii waa fashilantay.',
      );
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessageEn: null, errorMessageSo: null);
    try {
      final newUser = await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      state = AuthState(user: newUser);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: e.messageEn, errorMessageSo: e.messageSo);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessageEn: 'Failed to create account.',
        errorMessageSo: 'Waa uu guuldarraystay abuurista akoonku.',
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required UserRole role,
    String? email,
  }) async {
    final currentUser = _repository.currentUser;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true, errorMessageEn: null, errorMessageSo: null);
    try {
      final user = await _repository.registerUser(
        uid: currentUser.uid,
        fullName: fullName,
        phone: phone,
        role: role,
        email: email,
      );
      state = AuthState(user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: e.messageEn, errorMessageSo: e.messageSo);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessageEn: 'Registration failed.',
        errorMessageSo: 'Isdiiwaangelintii waa fashilantay.',
      );
    }
  }

  Future<void> uploadKyc({required String licenseUrl, required String idCardUrl}) async {
    final user = state.user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessageEn: null, errorMessageSo: null);
    try {
      await _repository.completeKyc(uid: user.uid, licenseUrl: licenseUrl, idCardUrl: idCardUrl);
      final updatedUser = user.copyWith(
        licenseImageUrl: licenseUrl,
        idCardImageUrl: idCardUrl,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(isLoading: false, user: updatedUser);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: e.messageEn, errorMessageSo: e.messageSo);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: 'Failed to save KYC documents.', errorMessageSo: 'Ku guuldarraystay kaydinta dukumeentiyada KYC.');
    }
  }

  Future<void> uploadProfilePhoto(String photoUrl) async {
    final user = state.user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessageEn: null, errorMessageSo: null);
    try {
      await _repository.updateProfileImage(uid: user.uid, photoUrl: photoUrl);
      final updatedUser = user.copyWith(
        profileImageUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(isLoading: false, user: updatedUser);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: e.messageEn, errorMessageSo: e.messageSo);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessageEn: 'Failed to upload photo.', errorMessageSo: 'Ku guuldarraystay gudbinta sawirka.');
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    state = AuthState();
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteAccount();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final adminUsersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getAllUsers();
});
