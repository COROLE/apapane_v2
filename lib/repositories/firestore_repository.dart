import 'dart:typed_data';

import 'package:apapane/models/result/result.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/typedefs/result_typedef.dart';

import '../services/firestore/firestore_service.dart';

class FirestoreRepository {
  final FirestoreService _firestoreService;
  FirestoreRepository(
    this._firestoreService,
  );

  FutureResult<bool> createDoc(DocRef ref, SDMap data) async {
    try {
      await _firestoreService.createDoc(ref, data);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> updateDoc(DocRef ref, SDMap data) async {
    try {
      await _firestoreService.updateDoc(ref, data);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> deleteDoc(DocRef ref) async {
    try {
      await _firestoreService.deleteDoc(ref);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<Doc> getDoc(DocRef ref) async {
    try {
      final Doc doc = await _firestoreService.getDoc(ref);
      return Result.success(doc);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<List<QDoc>> getDocs(MapQuery query) async {
    try {
      final QSnapshot qSnapshot = await _firestoreService.getDocs(query);
      final qDocs = qSnapshot.docs;
      return Result.success(qDocs);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<String> uploadImage(String path, Uint8List imageData) async {
    try {
      final downloadUrl = await _firestoreService.uploadImage(path, imageData);
      return Result.success(downloadUrl);
    } catch (e) {
      return const Result.failure();
    }
  }
}
