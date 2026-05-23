import 'dart:typed_data';
import 'dart:convert';
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
      // Return a base64 Data URI so the actual image chosen by the user is rendered
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
