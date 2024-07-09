import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/purchase/purchase.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getUserCoinCount(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(userId).get();
    Map<String, dynamic>? data = doc.data();
    return data?['coins'] ?? 0;
  }

  Future<void> updateUserPurchase(String userId, Purchase purchase) async {
    await _firestore.collection('users').doc(userId).update({
      'purchases': FieldValue.arrayUnion([purchase.toJson()]),
    });

    if (purchase.productID == 'consumable') {
      await _firestore.collection('users').doc(userId).update({
        'coins': FieldValue.increment(1),
      });
    }
  }

  Future<void> consumeCoin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'coins': FieldValue.increment(-1),
    });
  }
}
