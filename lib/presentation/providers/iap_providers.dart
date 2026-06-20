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
        next.when(
          data: (purchases) => _handlePurchases(purchases),
          loading: () {
            // Do not set global state to loading just because stream is initializing
            debugPrint('--- IAP DEBUG: purchaseStream is loading... ---');
          },
          error: (err, stack) {
            debugPrint('--- IAP DEBUG: purchaseStream error=$err ---');
            state = AsyncValue.error(err, stack);
          },
        );
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription? _subscription;
  bool _isProcessing = false;

  void reset() {
    state = const AsyncValue.data(null);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    if (_isProcessing) return;

    if (purchases.isEmpty && state.isLoading) {
      // If we were waiting for something and the list is now empty, reset.
      reset();
      return;
    }

    for (final purchase in purchases) {
      debugPrint('--- IAP DEBUG: purchase status=${purchase.status} id=${purchase.purchaseID} ---');
      
      if (purchase.status == PurchaseStatus.pending) {
        // Only show loading if we aren't already processing something else
        if (!state.isLoading) {
          state = const AsyncValue.loading();
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('--- IAP DEBUG: purchase error=${purchase.error} ---');
        final errorMsg = purchase.error?.message ?? 'Purchase failed';
        state = AsyncValue.error(errorMsg, StackTrace.current);
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
      
      if (user == null) {
        debugPrint('--- IAP WARN: No user logged in. Postponing verification... ---');
        state = const AsyncValue.data(null);
        return; // Do NOT complete purchase if no user is present to mark as paid
      }

      // Check if already paid in local state first
      final hasPaid = ref.read(hasPaidProvider);
      
      if (!hasPaid) {
        debugPrint('--- IAP DEBUG: Syncing purchase ${purchase.purchaseID} to DB for ${user.id} ---');
        
        // 1. Update the database
        await ref.read(authRepositoryProvider).markAsPaid(
          user.id,
          transactionId: purchase.purchaseID ?? 'google_iap_${DateTime.now().millisecondsSinceEpoch}',
          amount: AppConfig.unlockAmountKes.toDouble(),
        ).timeout(const Duration(seconds: 25)); // Slightly longer than repo internal timeout
      } else {
        debugPrint('--- IAP DEBUG: User already marked as paid. skipping DB sync. ---');
      }

      // 2. Complete the purchase in the store
      await ref.read(iapRepositoryProvider).completePurchase(purchase);
      
      // 3. Refresh user profile
      ref.invalidate(userProfileProvider);
      
      // Short delay to ensure Supabase propagation and UI smoothness
      await Future.delayed(const Duration(seconds: 2));
      
      state = const AsyncValue.data(null);
      debugPrint('--- IAP SUCCESS: Purchase fully processed ---');
    } catch (e) {
      debugPrint('--- IAP ERROR: Sync failed: $e ---');
      state = AsyncValue.error('Account unlock failed: $e', StackTrace.current);
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
      // Note: The stream listener will handle the result (purchased/error/pending)
    } catch (e) {
      debugPrint('--- IAP ERROR: Buy trigger failed: $e ---');
      final msg = e.toString().toLowerCase();
      if (msg.contains('already_owned') || msg.contains('already owned')) {
        state = AsyncValue.error('You already own this item. Tap "Restore Purchase" to unlock.', StackTrace.current);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> restorePurchases() async {
    try {
      state = const AsyncValue.loading();
      debugPrint('--- IAP DEBUG: Triggering restorePurchases ---');
      await ref.read(iapRepositoryProvider).restorePurchases();
      
      // Wait a few seconds for the stream to emit something. 
      // If it doesn't emit any 'restored' items, we should clear the loading state.
      await Future.delayed(const Duration(seconds: 4));
      if (mounted && state.isLoading) {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      debugPrint('--- IAP ERROR: Restore failed: $e ---');
      state = AsyncValue.error('Restore failed: $e', StackTrace.current);
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
