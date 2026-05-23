import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  final FirebaseStorage? _storage;

  StorageService() : _storage = Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null;

  /// Uploads file bytes to Firebase Storage under path: users/{uid}/{fileName}
  /// If Firebase is not initialized (e.g. simulated mode), it returns a simulated URL.
  Future<String> uploadBytes({
    required String uid,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (_storage != null) {
      final ref = _storage.ref().child('users').child(uid).child(fileName);
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } else {
      // Offline/simulation mode mock URLs with unique time key to prevent cache mismatch
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (fileName.contains('profile')) {
        return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&simulated_t=$timestamp';
      } else if (fileName.contains('license')) {
        return 'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?auto=format&fit=crop&w=600&simulated_t=$timestamp';
      } else {
        return 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=600&simulated_t=$timestamp';
      }
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
