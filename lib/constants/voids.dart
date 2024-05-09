//packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as fluttertoast;
//constants
import 'package:apapane/constants/bools.dart';

//onRefreshの内部
Future<void> processNewDocs(
    {required List<String> muteUids,
    required List<DocumentSnapshot<Map<String, dynamic>>> docs,
    required Query<Map<String, dynamic>> query}) async {
  if (docs.isNotEmpty) {
    if (docs.isNotEmpty) {
      final qshot = await query.limit(30).endBeforeDocument(docs.first).get();
      final reversed = qshot.docs.reversed.toList();
      for (final doc in reversed) {
        if (isValidUser(muteUids: muteUids, doc: doc)) docs.insert(0, doc);
      }
    }
  }
}

//onReloadの内部
Future<void> processBasicDocs(
    {required List<String> muteUids,
    required List<DocumentSnapshot<Map<String, dynamic>>> docs,
    required Query<Map<String, dynamic>> query}) async {
  final qshot = await query.limit(30).get();
  for (final doc in qshot.docs) {
    //doc['uid']は投稿主のuid
    //!は否定演算子
    if (isValidUser(muteUids: muteUids, doc: doc) && !docs.contains(doc)) {
      docs.add(doc);
    }
  }
}

//onLoadingの内部
Future<void> processOldDocs(
    {required List<String> muteUids,
    required List<DocumentSnapshot<Map<String, dynamic>>> docs,
    required Query<Map<String, dynamic>> query}) async {
  if (docs.isNotEmpty) {
    final qshot = await query.limit(30).startAfterDocument(docs.last).get();
    for (final doc in qshot.docs) {
      if (isValidUser(muteUids: muteUids, doc: doc)) docs.add(doc);
    }
  }
}

Future<void> showFluttertoast({required String msg}) async {
  //flashにToastが定義されているのでasを使って区別する
  await fluttertoast.Fluttertoast.showToast(
    msg: msg,
    toastLength: fluttertoast.Toast.LENGTH_SHORT,
    gravity: fluttertoast.ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.pink,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
