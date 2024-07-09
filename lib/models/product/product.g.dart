// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      currencyCode: json['currencyCode'] as String,
      isSubscription: json['isSubscription'] as bool,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'currencyCode': instance.currencyCode,
      'isSubscription': instance.isSubscription,
    };
