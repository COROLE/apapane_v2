import 'dart:typed_data';

import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  Future<void> createDoc(DocRef ref, SDMap data) async => ref.set(data);

  Future<void> updateDoc(DocRef ref, SDMap data) async => ref.update(data);

  Future<void> deleteDoc(DocRef ref) async => ref.delete();

  FutureDoc getDoc(DocRef ref) async => ref.get();

  FutureQSnapshot getDocs(MapQuery query) async => query.get();

  Future<String> uploadImage(String path, Uint8List imageData) async {
    final normalizedPath = path.replaceAll('\\', '/');
    final ref = FirebaseStorage.instance.ref(normalizedPath);
    final metadata = SettableMetadata(contentType: _contentTypeForPath(path));
    await ref.putData(imageData, metadata);
    return ref.getDownloadURL();
  }

  String _contentTypeForPath(String path) {
    final lowered = path.toLowerCase();
    if (lowered.endsWith('.png')) {
      return 'image/png';
    }
    return 'image/jpeg';
  }
}
