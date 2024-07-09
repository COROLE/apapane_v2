import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String title,
    required String description,
    required String price,
    required String currencyCode,
    required bool isSubscription,
  }) = _Product;

  factory Product.fromProductDetails(ProductDetails details) {
    return Product(
      id: details.id,
      title: details.title,
      description: details.description,
      price: details.price,
      currencyCode: details.currencyCode,
      isSubscription: details.id == 'silver_subscription',
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  ProductDetails toProductDetails() {
    return ProductDetails(
      id: id,
      title: title,
      description: description,
      price: price,
      rawPrice: double.parse(price.replaceAll(RegExp(r'[^\d.]'), '')),
      currencyCode: currencyCode,
    );
  }
}
