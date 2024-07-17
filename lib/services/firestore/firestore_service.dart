import 'dart:typed_data';

import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  Future<void> createDoc(DocRef ref, SDMap data) async => await ref.set(data);
  Future<void> updateDoc(DocRef ref, SDMap data) async =>
      await ref.update(data);
  Future<void> deleteDoc(DocRef ref) async => await ref.delete();
  FutureDoc getDoc(DocRef ref) async => await ref.get();
  FutureQSnapshot getDocs(MapQuery query) async => await query.get();

  Future<String> uploadImage(String path, Uint8List imageData) async {
    Reference storageRef = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = storageRef.putData(imageData);
    // アップロードが完了するのを待つ
    await uploadTask;
    // アップロードが成功したかどうかを確認
    if (uploadTask.snapshot.state == TaskState.success) {
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } else {
      // アップロードが失敗した場合の処理
      throw Exception('ファイルのアップロードに失敗しました');
    }
  }
}
