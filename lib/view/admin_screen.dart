import 'package:apapane/details/rounded_button.dart';
import 'package:apapane/domain/firestore_user/firestore_user.dart';
import 'package:apapane/model/admin_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen(
      {super.key, required this.currentUserDoc, required this.firestoreUser});
  final DocumentSnapshot<Map<String, dynamic>> currentUserDoc;
  final FirestoreUser firestoreUser;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdminModel adminModel = ref.watch(adminProvider);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Screen'),
        ),
        body: Center(
            child: RoundedButton(
                onPressed: () => adminModel.admin(
                    currentUserDoc: currentUserDoc,
                    firestoreUser: firestoreUser),
                widthRate: 0.6,
                color: Colors.black,
                text: 'Admin')));
  }
}
