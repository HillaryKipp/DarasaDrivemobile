import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config/app_config.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final iapProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final repo = ref.watch(iapRepositoryProvider);
  final available = await repo.isAvailable();
  if (!available) return [];
  return repo.fetchProducts({AppConfig.iapUnlockProductId});
});

final iapPurchaseProvider = StreamProvider<List<PurchaseDetails>>((ref) {
  return ref.watch(iapRepositoryProvider).purchaseStream;
});

/// A notifier to manage the overall IAP flow state.
class IapStateNotifier extends StateNotifier<AsyncValue<void>> {
  IapStateNotifier(this.ref) : super(const AsyncValue.data(null)) {
    _subscription = ref.listen(iapPurchaseProvider, (previous, next) {
      next.whenData((purchases) {
        _handlePurchases(purchases);
      });
    });
  }

  final Ref ref;
  // ignore: unused_field
  ProviderSubscription? _subscription;

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        state = const AsyncValue.loading();
      } else if (purchase.status == PurchaseStatus.error) {
        state = AsyncValue.error(purchase.error!, StackTrace.current);
        await ref.read(iapRepositoryProvider).completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Here we should verify the purchase with the backend
        // For simplicity, we'll assume success and refresh the profile
        await _verifyAndUnlock(purchase);
      }
    }
  }

  Future<void> _verifyAndUnlock(PurchaseDetails purchase) async {
    try {
      // 1. Notify backend (You might need a new endpoint for this)
      // For now, we'll try to refresh the profile assuming the backend 
      // is notified via webhooks or similar.
      // Or we can manually trigger a sync if the repository supports it.
      
      // 2. Complete the purchase in the store
      await ref.read(iapRepositoryProvider).completePurchase(purchase);
      
      // 3. Refresh user profile
      ref.invalidate(userProfileProvider);
      await ref.read(userProfileProvider.future);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> buyUnlock(ProductDetails product) async {
    try {
      state = const AsyncValue.loading();
      await ref.read(iapRepositoryProvider).buyProduct(product);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

final iapStateNotifierProvider =
    StateNotifierProvider<IapStateNotifier, AsyncValue<void>>((ref) {
  return IapStateNotifier(ref);
});
