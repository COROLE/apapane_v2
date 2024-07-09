import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

part 'purchase.freezed.dart';
part 'purchase.g.dart';

@freezed
class Purchase with _$Purchase {
  const factory Purchase({
    required String productID,
    required String purchaseID,
    required String transactionDate,
    required PurchaseStatus status,
    @Default('') dynamic startDate, // デフォルト値を設定
    @Default('') dynamic endDate, // デフォルト値を設定
  }) = _Purchase;

  factory Purchase.fromPurchaseDetails(PurchaseDetails details) {
    return Purchase(
      productID: details.productID,
      purchaseID: details.purchaseID ?? '',
      transactionDate: details.transactionDate ?? '',
      status: details.status,
    );
  }

  factory Purchase.fromJson(Map<String, dynamic> json) =>
      _$PurchaseFromJson(json);

  factory Purchase.createWithDates({
    required Purchase purchase,
  }) {
    int transactionTimestamp = int.parse(purchase.transactionDate);
    DateTime transactionDateTime =
        DateTime.fromMillisecondsSinceEpoch(transactionTimestamp);
    DateTime startDateTime = transactionDateTime;
    DateTime endDateTime = DateTime(
      transactionDateTime.year,
      transactionDateTime.month + 1,
      transactionDateTime.day,
    );

    return Purchase(
      productID: purchase.productID,
      purchaseID: purchase.purchaseID,
      transactionDate: purchase.transactionDate,
      status: purchase.status,
      startDate: Timestamp.fromDate(startDateTime), // Firestoreタイムスタンプに変換
      endDate: Timestamp.fromDate(endDateTime), // Firestoreタイムスタンプに変換
    );
  }
}
