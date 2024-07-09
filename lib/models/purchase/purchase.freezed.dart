// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Purchase _$PurchaseFromJson(Map<String, dynamic> json) {
  return _Purchase.fromJson(json);
}

/// @nodoc
mixin _$Purchase {
  String get productID => throw _privateConstructorUsedError;
  String get purchaseID => throw _privateConstructorUsedError;
  String get transactionDate => throw _privateConstructorUsedError;
  PurchaseStatus get status => throw _privateConstructorUsedError;
  dynamic get startDate => throw _privateConstructorUsedError; // デフォルト値を設定
  dynamic get endDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseCopyWith<Purchase> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseCopyWith<$Res> {
  factory $PurchaseCopyWith(Purchase value, $Res Function(Purchase) then) =
      _$PurchaseCopyWithImpl<$Res, Purchase>;
  @useResult
  $Res call(
      {String productID,
      String purchaseID,
      String transactionDate,
      PurchaseStatus status,
      dynamic startDate,
      dynamic endDate});
}

/// @nodoc
class _$PurchaseCopyWithImpl<$Res, $Val extends Purchase>
    implements $PurchaseCopyWith<$Res> {
  _$PurchaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productID = null,
    Object? purchaseID = null,
    Object? transactionDate = null,
    Object? status = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
  }) {
    return _then(_value.copyWith(
      productID: null == productID
          ? _value.productID
          : productID // ignore: cast_nullable_to_non_nullable
              as String,
      purchaseID: null == purchaseID
          ? _value.purchaseID
          : purchaseID // ignore: cast_nullable_to_non_nullable
              as String,
      transactionDate: null == transactionDate
          ? _value.transactionDate
          : transactionDate // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PurchaseStatus,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as dynamic,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseImplCopyWith<$Res>
    implements $PurchaseCopyWith<$Res> {
  factory _$$PurchaseImplCopyWith(
          _$PurchaseImpl value, $Res Function(_$PurchaseImpl) then) =
      __$$PurchaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String productID,
      String purchaseID,
      String transactionDate,
      PurchaseStatus status,
      dynamic startDate,
      dynamic endDate});
}

/// @nodoc
class __$$PurchaseImplCopyWithImpl<$Res>
    extends _$PurchaseCopyWithImpl<$Res, _$PurchaseImpl>
    implements _$$PurchaseImplCopyWith<$Res> {
  __$$PurchaseImplCopyWithImpl(
      _$PurchaseImpl _value, $Res Function(_$PurchaseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productID = null,
    Object? purchaseID = null,
    Object? transactionDate = null,
    Object? status = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
  }) {
    return _then(_$PurchaseImpl(
      productID: null == productID
          ? _value.productID
          : productID // ignore: cast_nullable_to_non_nullable
              as String,
      purchaseID: null == purchaseID
          ? _value.purchaseID
          : purchaseID // ignore: cast_nullable_to_non_nullable
              as String,
      transactionDate: null == transactionDate
          ? _value.transactionDate
          : transactionDate // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PurchaseStatus,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as dynamic,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseImpl implements _Purchase {
  const _$PurchaseImpl(
      {required this.productID,
      required this.purchaseID,
      required this.transactionDate,
      required this.status,
      this.startDate = '',
      this.endDate = ''});

  factory _$PurchaseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseImplFromJson(json);

  @override
  final String productID;
  @override
  final String purchaseID;
  @override
  final String transactionDate;
  @override
  final PurchaseStatus status;
  @override
  @JsonKey()
  final dynamic startDate;
// デフォルト値を設定
  @override
  @JsonKey()
  final dynamic endDate;

  @override
  String toString() {
    return 'Purchase(productID: $productID, purchaseID: $purchaseID, transactionDate: $transactionDate, status: $status, startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseImpl &&
            (identical(other.productID, productID) ||
                other.productID == productID) &&
            (identical(other.purchaseID, purchaseID) ||
                other.purchaseID == purchaseID) &&
            (identical(other.transactionDate, transactionDate) ||
                other.transactionDate == transactionDate) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other.startDate, startDate) &&
            const DeepCollectionEquality().equals(other.endDate, endDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      productID,
      purchaseID,
      transactionDate,
      status,
      const DeepCollectionEquality().hash(startDate),
      const DeepCollectionEquality().hash(endDate));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseImplCopyWith<_$PurchaseImpl> get copyWith =>
      __$$PurchaseImplCopyWithImpl<_$PurchaseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseImplToJson(
      this,
    );
  }
}

abstract class _Purchase implements Purchase {
  const factory _Purchase(
      {required final String productID,
      required final String purchaseID,
      required final String transactionDate,
      required final PurchaseStatus status,
      final dynamic startDate,
      final dynamic endDate}) = _$PurchaseImpl;

  factory _Purchase.fromJson(Map<String, dynamic> json) =
      _$PurchaseImpl.fromJson;

  @override
  String get productID;
  @override
  String get purchaseID;
  @override
  String get transactionDate;
  @override
  PurchaseStatus get status;
  @override
  dynamic get startDate;
  @override // デフォルト値を設定
  dynamic get endDate;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseImplCopyWith<_$PurchaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
