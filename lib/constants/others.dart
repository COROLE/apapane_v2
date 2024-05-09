//packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//returnAuthUser
User? returnAuthUser() => FirebaseAuth.instance.currentUser;

DocumentReference<Map<String, dynamic>> userDocToChatLogIdRef(
    {required DocumentSnapshot<Map<String, dynamic>> userDoc,
    required String id}) {
  return userDoc.reference.collection('chatLogs').doc(id);
}
