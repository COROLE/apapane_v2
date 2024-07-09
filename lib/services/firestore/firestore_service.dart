import 'package:apapane/typedefs/firestore_typedef.dart';

class FirestoreService {
  Future<void> createDoc(DocRef ref, SDMap data) async => await ref.set(data);
  Future<void> updateDoc(DocRef ref, SDMap data) async =>
      await ref.update(data);
  Future<void> deleteDoc(DocRef ref) async => await ref.delete();
  FutureDoc getDoc(DocRef ref) async => await ref.get();
  FutureQSnapshot getDocs(MapQuery query) async => await query.get();
}
