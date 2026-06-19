import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/repositories/iap_repository.dart';

class IapRepositoryImpl implements IapRepository {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() async {
    return await _iap.isAvailable();
  }

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> ids) async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    return response.productDetails;
  }

  @override
  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    // Non-consumable for account unlock
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  @override
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}
