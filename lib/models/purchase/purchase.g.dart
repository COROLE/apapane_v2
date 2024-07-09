// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseImpl _$$PurchaseImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseImpl(
      productID: json['productID'] as String,
      purchaseID: json['purchaseID'] as String,
      transactionDate: json['transactionDate'] as String,
      status: $enumDecode(_$PurchaseStatusEnumMap, json['status']),
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
    );

Map<String, dynamic> _$$PurchaseImplToJson(_$PurchaseImpl instance) =>
    <String, dynamic>{
      'productID': instance.productID,
      'purchaseID': instance.purchaseID,
      'transactionDate': instance.transactionDate,
      'status': _$PurchaseStatusEnumMap[instance.status]!,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

const _$PurchaseStatusEnumMap = {
  PurchaseStatus.pending: 'pending',
  PurchaseStatus.purchased: 'purchased',
  PurchaseStatus.error: 'error',
  PurchaseStatus.restored: 'restored',
  PurchaseStatus.canceled: 'canceled',
};
