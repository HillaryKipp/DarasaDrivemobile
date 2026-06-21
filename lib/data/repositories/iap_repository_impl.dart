import 'dart:async';
import 'dart:developer' as developer;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/repositories/iap_repository.dart';

class IapRepositoryImpl implements IapRepository {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() async {
    final available = await _iap.isAvailable();
    developer.log('IAP: isAvailable = $available', name: 'IapRepo');
    return available;
  }

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> ids) async {
    developer.log('IAP: fetchProducts ids=$ids', name: 'IapRepo');
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      developer.log('IAP: fetchProducts ERROR: ${response.error!.message}', name: 'IapRepo');
      throw Exception(response.error!.message);
    }
    developer.log('IAP: fetchProducts SUCCESS found ${response.productDetails.length}', name: 'IapRepo');
    return response.productDetails;
  }

  @override
  Future<void> buyProduct(ProductDetails product) async {
    developer.log('IAP: buyProduct START id=${product.id}', name: 'IapRepo');
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      // Non-consumable for account unlock
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      developer.log('IAP: buyProduct trigger SENT', name: 'IapRepo');
    } catch (e) {
      developer.log('IAP: buyProduct trigger ERROR: $e', name: 'IapRepo');
      rethrow;
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    developer.log('IAP: completePurchase START id=${purchase.purchaseID} status=${purchase.status}', name: 'IapRepo');
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
        developer.log('IAP: completePurchase SUCCESS', name: 'IapRepo');
      } catch (e) {
        developer.log('IAP: completePurchase ERROR: $e', name: 'IapRepo');
      }
    } else {
      developer.log('IAP: completePurchase SKIPPED (not pending)', name: 'IapRepo');
    }
  }

  @override
  Future<void> restorePurchases() async {
    developer.log('IAP: restorePurchases START', name: 'IapRepo');
    try {
      await _iap.restorePurchases();
      developer.log('IAP: restorePurchases request SENT', name: 'IapRepo');
    } catch (e) {
      developer.log('IAP: restorePurchases ERROR: $e', name: 'IapRepo');
      rethrow;
    }
  }
}
