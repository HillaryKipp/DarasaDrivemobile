import 'package:in_app_purchase/in_app_purchase.dart';

abstract class IapRepository {
  /// Stream of purchase updates.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Returns true if the store is available.
  Future<bool> isAvailable();

  /// Fetches products from the store.
  Future<List<ProductDetails>> fetchProducts(Set<String> ids);

  /// Initiates a purchase for a product.
  Future<void> buyProduct(ProductDetails product);

  /// Completes a purchase.
  Future<void> completePurchase(PurchaseDetails purchase);

  /// Restores previous purchases.
  Future<void> restorePurchases();
}
