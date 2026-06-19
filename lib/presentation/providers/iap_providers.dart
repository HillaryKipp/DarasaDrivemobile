import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config/app_config.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final iapProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  if (kIsWeb) return [];
  
  final repo = ref.watch(iapRepositoryProvider);
  final available = await repo.isAvailable();
  
  debugPrint('--- IAP DEBUG: available=$available ---');
  
  if (!available) return [];
  
  try {
    final products = await repo.fetchProducts({AppConfig.iapUnlockProductId});
    debugPrint('--- IAP DEBUG: products_found=${products.length} id=${AppConfig.iapUnlockProductId} ---');
    return products;
  } catch (e) {
    debugPrint('--- IAP DEBUG: fetch_error=$e ---');
    return [];
  }
});

final iapPurchaseProvider = StreamProvider<List<PurchaseDetails>>((ref) {
  if (kIsWeb) return const Stream.empty();
  return ref.watch(iapRepositoryProvider).purchaseStream;
});

/// A notifier to manage the overall IAP flow state.
class IapStateNotifier extends StateNotifier<AsyncValue<void>> {
  IapStateNotifier(this.ref) : super(const AsyncValue.data(null)) {
    if (!kIsWeb) {
      _subscription = ref.listen(iapPurchaseProvider, (previous, next) {
        next.whenData((purchases) {
          _handlePurchases(purchases);
        });
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription? _subscription;
  bool _isProcessing = false;

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    if (_isProcessing) return;

    for (final purchase in purchases) {
      debugPrint('--- IAP DEBUG: purchase status=${purchase.status} id=${purchase.purchaseID} ---');
      
      if (purchase.status == PurchaseStatus.pending) {
        state = const AsyncValue.loading();
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('--- IAP DEBUG: purchase error=${purchase.error} ---');
        state = AsyncValue.error(purchase.error ?? 'Purchase failed', StackTrace.current);
        await ref.read(iapRepositoryProvider).completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _isProcessing = true;
        try {
          await _verifyAndUnlock(purchase);
        } finally {
          _isProcessing = false;
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        state = const AsyncValue.data(null);
      }
    }
  }

  Future<void> _verifyAndUnlock(PurchaseDetails purchase) async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(currentUserProvider);
      
      if (user != null) {
        debugPrint('--- IAP DEBUG: Syncing purchase ${purchase.purchaseID} to DB for ${user.id} ---');
        
        // 1. Update the database
        await ref.read(authRepositoryProvider).markAsPaid(
          user.id,
          transactionId: purchase.purchaseID ?? 'google_iap_${DateTime.now().millisecondsSinceEpoch}',
          amount: AppConfig.unlockAmountKes.toDouble(),
        );
      }

      // 2. Complete the purchase in the store
      await ref.read(iapRepositoryProvider).completePurchase(purchase);
      
      // 3. Refresh user profile
      ref.invalidate(userProfileProvider);
      
      // Short delay to ensure Supabase propagation
      await Future.delayed(const Duration(seconds: 1));
      
      state = const AsyncValue.data(null);
      debugPrint('--- IAP SUCCESS: Purchase fully processed ---');
    } catch (e) {
      debugPrint('--- IAP ERROR: Sync failed: $e ---');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> buyUnlock(ProductDetails product) async {
    if (kIsWeb) {
      state = AsyncValue.error('Google Play Billing is not supported in web previews.', StackTrace.current);
      return;
    }

    try {
      state = const AsyncValue.loading();
      await ref.read(iapRepositoryProvider).buyProduct(product);
    } catch (e) {
      debugPrint('--- IAP ERROR: Buy trigger failed: $e ---');
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
