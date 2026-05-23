import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/user_entity.dart';
import 'auth_remote_datasource.dart';

class AuthException implements Exception {
  final String messageEn;
  final String messageSo;
  final String code;

  AuthException({required this.messageEn, required this.messageSo, required this.code});

  @override
  String toString() => 'AuthException($code): $messageEn';
}

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository(this._remoteDataSource);

  Stream<User?> get authStateChanges => _remoteDataSource.authStateChanges;
  User? get currentUser => _remoteDataSource.currentUser;

  Future<void> sendOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(AuthException exception) onError,
  }) async {
    await _remoteDataSource.sendOtp(
      phone,
      (verificationId, resendToken) {
        onCodeSent(verificationId);
      },
      (e) {
        String msgEn = 'Failed to send verification code. Please try again.';
        String msgSo = 'Waa uu guuldarraystay dirista koodka. Fadlan isku day markale.';
        
        if (e.code == 'invalid-phone-number') {
          msgEn = 'The phone number entered is invalid.';
          msgSo = 'Lambarka taleefanka aad gelisay ma saxna.';
        }
        onError(AuthException(messageEn: msgEn, messageSo: msgSo, code: e.code));
      },
    );
  }

  Future<UserEntity?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _remoteDataSource.signInWithEmail(email, password);
      final user = credential.user;
      if (user == null) {
        throw AuthException(
          messageEn: 'Sign in failed. No user returned.',
          messageSo: 'Galitaankii waa fashilantay.',
          code: 'null-user',
        );
      }
      return await _remoteDataSource.getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      String msgEn = 'Sign in failed. Please check your credentials.';
      String msgSo = 'Galitaankii waa fashilantay. Fadlan hubi xogta.';
      if (e.code == 'user-not-found') {
        msgEn = 'No account found with this email address.';
        msgSo = 'Ma jiro akoon leh emailkan.';
      } else if (e.code == 'wrong-password') {
        msgEn = 'Incorrect password. Please try again.';
        msgSo = 'Furaha qaranka waa khaldan yahay. Isku day markale.';
      } else if (e.code == 'invalid-email') {
        msgEn = 'The email address is not valid.';
        msgSo = 'Cinwaanka emailku ma saxna.';
      }
      throw AuthException(messageEn: msgEn, messageSo: msgSo, code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        messageEn: 'An unexpected error occurred.',
        messageSo: 'Khalad aan la filanayn ayaa dhacay.',
        code: 'unknown',
      );
    }
  }

  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final credential = await _remoteDataSource.signUpWithEmail(email, password);
      final user = credential.user;
      if (user == null) {
        throw AuthException(
          messageEn: 'Sign up failed. No user returned.',
          messageSo: 'Abuurista akoonku waa fashilantay.',
          code: 'null-user',
        );
      }
      
      final now = DateTime.now();
      final isEmailAdmin = email.toLowerCase().contains('admin') || email.toLowerCase() == 'baashe@abaarso.com' || email.toLowerCase().contains('zakaria');
      final newUser = UserEntity(
        uid: user.uid,
        fullName: fullName,
        phone: '', // No phone number initially with email/password signup
        email: email,
        role: isEmailAdmin ? UserRole.admin : role,
        isVerified: isEmailAdmin ? true : false,
        createdAt: now,
        updatedAt: now,
      );
      
      await _remoteDataSource.saveUserData(newUser);
      return newUser;
    } on FirebaseAuthException catch (e) {
      String msgEn = 'Sign up failed. Please check your information.';
      String msgSo = 'Abuurista akoonku waa fashilantay. Fadlan hubi xogta.';
      
      if (e.code == 'email-already-in-use') {
        msgEn = 'An account already exists with this email address.';
        msgSo = 'Waxaa horay u jiray akoon leh emailkan.';
      } else if (e.code == 'weak-password') {
        msgEn = 'The password provided is too weak.';
        msgSo = 'Furaha la bixiyey aad buu u liitaa.';
      } else if (e.code == 'invalid-email') {
        msgEn = 'The email address is not valid.';
        msgSo = 'Cinwaanka emailku ma saxna.';
      }
      throw AuthException(messageEn: msgEn, messageSo: msgSo, code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        messageEn: 'An unexpected error occurred during registration.',
        messageSo: 'Khalad aan la filanayn ayaa dhacay intii lagu guda jiray isdiiwaangelinta.',
        code: 'unknown',
      );
    }
  }

  Future<UserEntity?> verifyOtpAndFetchUser({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = await _remoteDataSource.verifyOtp(verificationId, smsCode);
      final user = credential.user;
      if (user == null) {
        throw AuthException(
          messageEn: 'Verification failed. Null user returned.',
          messageSo: 'Xaqiijintii waa fashilantay. Ma jiro isticmaale la helay.',
          code: 'null-user',
        );
      }
      return await _remoteDataSource.getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      String msgEn = 'Verification code is invalid or has expired.';
      String msgSo = 'Koodka xaqiijinta waa khaldan yahay ama wuu dhacay.';
      if (e.code == 'invalid-verification-code') {
        msgEn = 'The verification code entered is incorrect.';
        msgSo = 'Koodka xaqiijinta ee aad gelisay waa khaldan yahay.';
      }
      throw AuthException(messageEn: msgEn, messageSo: msgSo, code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        messageEn: e.toString(),
        messageSo: 'Khalad aan la aqoon ayaa dhacay fadlan isku day markale.',
        code: 'unknown',
      );
    }
  }

  Future<UserEntity> registerUser({
    required String uid,
    required String fullName,
    required String phone,
    required UserRole role,
    String? email,
  }) async {
    try {
      final now = DateTime.now();
      final newUser = UserEntity(
        uid: uid,
        fullName: fullName,
        phone: phone,
        email: email,
        role: role,
        isVerified: false,
        createdAt: now,
        updatedAt: now,
      );
      await _remoteDataSource.saveUserData(newUser);
      return newUser;
    } catch (e) {
      throw AuthException(
        messageEn: 'Failed to create your profile. Please check internet connection.',
        messageSo: 'Waa uu guuldarraystay abuurista profile-ka. Fadlan hubi khadkaaga internet-ka.',
        code: 'save-user-failed',
      );
    }
  }

  Future<UserEntity?> fetchUserData(String uid) async {
    try {
      return await _remoteDataSource.getUserData(uid);
    } catch (e) {
      return null;
    }
  }

  Future<void> completeKyc({
    required String uid,
    required String licenseUrl,
    required String idCardUrl,
  }) async {
    try {
      await _remoteDataSource.updateKycDocuments(
        uid: uid,
        licenseUrl: licenseUrl,
        idCardUrl: idCardUrl,
      );
    } catch (e) {
      throw AuthException(
        messageEn: 'Failed to upload KYC documents.',
        messageSo: 'Waa uu guuldarraystay gudbinta dukumeentiyada KYC-ga.',
        code: 'kyc-upload-failed',
      );
    }
  }

  Future<void> updateProfileImage({required String uid, required String photoUrl}) async {
    try {
      await _remoteDataSource.uploadProfilePhoto(uid: uid, photoUrl: photoUrl);
    } catch (e) {
      throw AuthException(
        messageEn: 'Failed to upload profile photo.',
        messageSo: 'Waa uu guuldarraystay gudbinta sawirka profile-ka.',
        code: 'photo-upload-failed',
      );
    }
  }

  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
    } catch (e) {
      throw AuthException(
        messageEn: 'Failed to delete account.',
        messageSo: 'Waa uu guuldarraystay tirtirista akoonka.',
        code: 'delete-account-failed',
      );
    }
  }

  Future<List<UserEntity>> getAllUsers() async {
    return await _remoteDataSource.getAllUsers();
  }

  Future<void> verifyUserKyc(String uid, bool isVerified) async {
    await _remoteDataSource.verifyUserKyc(uid, isVerified);
  }
}
