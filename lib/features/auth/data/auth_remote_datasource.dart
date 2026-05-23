import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/user_entity.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<void> sendOtp(String phone, Function(String verificationId, int? resendToken) onCodeSent, Function(FirebaseAuthException e) onError);
  Future<UserCredential> verifyOtp(String verificationId, String smsCode);
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserEntity?> getUserData(String uid);
  Future<void> saveUserData(UserEntity user);
  Future<void> updateKycDocuments({required String uid, required String licenseUrl, required String idCardUrl});
  Future<void> uploadProfilePhoto({required String uid, required String photoUrl});
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<List<UserEntity>> getAllUsers();
  Future<void> verifyUserKyc(String uid, bool isVerified);
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> sendOtp(
    String phone,
    Function(String verificationId, int? resendToken) onCodeSent,
    Function(FirebaseAuthException e) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError(FirebaseAuthException(code: 'send-otp-failed', message: e.toString()));
    }
  }

  @override
  Future<UserCredential> verifyOtp(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserEntity?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserEntity.fromMap(doc.data()!);
  }

  @override
  Future<void> saveUserData(UserEntity user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateKycDocuments({
    required String uid,
    required String licenseUrl,
    required String idCardUrl,
  }) async {
    await _db.collection('users').doc(uid).update({
      'licenseImageUrl': licenseUrl,
      'idCardImageUrl': idCardUrl,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> uploadProfilePhoto({required String uid, required String photoUrl}) async {
    await _db.collection('users').doc(uid).update({
      'profileImageUrl': photoUrl,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final snapshot = await _db.collection('users').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
  }

  @override
  Future<void> verifyUserKyc(String uid, bool isVerified) async {
    await _db.collection('users').doc(uid).update({
      'isVerified': isVerified,
      'updatedAt': Timestamp.now(),
    });
  }
}

// Robust fallback simulator for local offline testing (when Firebase config files are absent)
class SimulatedAuthRemoteDataSource implements AuthRemoteDataSource {
  final _controller = StreamController<User?>.broadcast();
  User? _currentUser;
  final Map<String, UserEntity> _simulatedDb = {};

  SimulatedAuthRemoteDataSource() {
    // Add default admin and customer accounts in simulation mode
    final now = DateTime.now();
    _simulatedDb['admin123'] = UserEntity(
      uid: 'admin123',
      fullName: 'Saeed Mohamed',
      phone: '+252634444444',
      email: 'saeed@abaarso.com',
      role: UserRole.admin,
      isVerified: true,
      createdAt: now,
      updatedAt: now,
    );
    _simulatedDb['baashe123'] = UserEntity(
      uid: 'baashe123',
      fullName: 'Baashe',
      phone: '+252637777777',
      email: 'baashe@abaarso.com',
      role: UserRole.admin,
      isVerified: true,
      createdAt: now,
      updatedAt: now,
    );
    _simulatedDb['zakaria123'] = UserEntity(
      uid: 'zakaria123',
      fullName: 'Zakaria123',
      phone: '+252636666666',
      email: 'zakaria@abaarso.com',
      role: UserRole.admin,
      isVerified: true,
      profileImageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      createdAt: now,
      updatedAt: now,
    );
    _simulatedDb['customer123'] = UserEntity(
      uid: 'customer123',
      fullName: 'Khadra Ali',
      phone: '+252635555555',
      email: 'khadra@gmail.com',
      role: UserRole.customer,
      isVerified: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<void> sendOtp(
    String phone,
    Function(String verificationId, int? resendToken) onCodeSent,
    Function(FirebaseAuthException e) onError,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    onCodeSent('simulated_ver_id_${phone.replaceAll('+', '')}', 12345);
  }

  @override
  Future<UserCredential> verifyOtp(String verificationId, String smsCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate user login
    final phone = '+${verificationId.replaceFirst('simulated_ver_id_', '')}';
    final uid = 'uid_${phone.replaceAll('+', '')}';
    
    // If not exists in DB, we'll create a placeholder that gets updated during RegisterScreen
    _currentUser = _SimulatedUser(uid: uid, phoneNumber: phone);
    _controller.add(_currentUser);

    return _SimulatedUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final sanitizedEmail = email.toLowerCase().trim();
    // Check if email already exists
    final exists = _simulatedDb.values.any((u) => u.email?.toLowerCase() == sanitizedEmail);
    if (exists) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );
    }
    
    final newUid = 'simulated_uid_${sanitizedEmail.hashCode}';
    _currentUser = _SimulatedUser(uid: newUid, phoneNumber: null);
    _controller.add(_currentUser);
    return _SimulatedUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Find user in simulated DB by email
    var match = _simulatedDb.entries
        .where((e) => e.value.email?.toLowerCase() == email.toLowerCase())
        .firstOrNull;
    if (match == null) {
      // Auto-register new customer for offline testing/verification friction-free!
      final now = DateTime.now();
      final sanitizedEmail = email.toLowerCase().trim();
      final isEmailAdmin = sanitizedEmail.contains('admin');
      final nameFromEmail = sanitizedEmail.split('@').first;
      final displayName = nameFromEmail.isNotEmpty 
          ? '${nameFromEmail[0].toUpperCase()}${nameFromEmail.substring(1)}'
          : 'Simulated User';
      final newUid = 'simulated_uid_${sanitizedEmail.hashCode}';
      
      final newUser = UserEntity(
        uid: newUid,
        fullName: displayName,
        phone: '+252636666666',
        email: sanitizedEmail,
        role: isEmailAdmin ? UserRole.admin : UserRole.customer,
        isVerified: isEmailAdmin ? true : false,
        createdAt: now,
        updatedAt: now,
      );
      _simulatedDb[newUid] = newUser;
      match = MapEntry(newUid, newUser);
    }
    final uid = match.key;
    _currentUser = _SimulatedUser(uid: uid, phoneNumber: match.value.phone);
    _controller.add(_currentUser);
    return _SimulatedUserCredential(_currentUser!);
  }

  @override
  Future<UserEntity?> getUserData(String uid) async {
    return _simulatedDb[uid];
  }

  @override
  Future<void> saveUserData(UserEntity user) async {
    _simulatedDb[user.uid] = user;
    if (_currentUser == null || _currentUser!.uid != user.uid) {
      _currentUser = _SimulatedUser(uid: user.uid, phoneNumber: user.phone);
      _controller.add(_currentUser);
    }
  }

  @override
  Future<void> updateKycDocuments({
    required String uid,
    required String licenseUrl,
    required String idCardUrl,
  }) async {
    final existing = _simulatedDb[uid];
    if (existing != null) {
      _simulatedDb[uid] = existing.copyWith(
        licenseImageUrl: licenseUrl,
        idCardImageUrl: idCardUrl,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> uploadProfilePhoto({required String uid, required String photoUrl}) async {
    final existing = _simulatedDb[uid];
    if (existing != null) {
      _simulatedDb[uid] = existing.copyWith(
        profileImageUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      _simulatedDb.remove(_currentUser!.uid);
      _currentUser = null;
      _controller.add(null);
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _simulatedDb.values.toList();
  }

  @override
  Future<void> verifyUserKyc(String uid, bool isVerified) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _simulatedDb[uid];
    if (existing != null) {
      _simulatedDb[uid] = existing.copyWith(
        isVerified: isVerified,
        updatedAt: DateTime.now(),
      );
    }
  }
}

// Simulated simple wrapper classes for Firebase Auth responses
class _SimulatedUser implements User {
  @override
  final String uid;
  @override
  final String? phoneNumber;

  _SimulatedUser({required this.uid, this.phoneNumber});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SimulatedUserCredential implements UserCredential {
  @override
  final User? user;

  _SimulatedUserCredential(this.user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
