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
  if (!available) return [];
  try {
    return await repo.fetchProducts({AppConfig.iapUnlockProductId});
  } catch (e) {
    return [];
  }
});

final iapPurchaseProvider = StreamProvider<List<PurchaseDetails>>((ref) {
  if (kIsWeb) return const Stream.empty();
  return ref.watch(iapRepositoryProvider).purchaseStream;
});

class IapStateNotifier extends StateNotifier<AsyncValue<void>> {
  IapStateNotifier(this.ref) : super(const AsyncValue.data(null)) {
    if (!kIsWeb) {
      _subscription = ref.listen<AsyncValue<List<PurchaseDetails>>>(iapPurchaseProvider, (previous, next) {
        if (next.isLoading) return;
        if (next.hasError) {
          state = AsyncValue.error(next.error!, next.stackTrace!);
          return;
        }
        final purchases = next.value ?? [];
        if (purchases.isNotEmpty) _handlePurchases(purchases);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription? _subscription;
  bool _isProcessing = false;
  final Set<String> _failedPurchaseIds = {};

  void reset() {
    _isProcessing = false;
    _failedPurchaseIds.clear();
    state = const AsyncValue.data(null);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    if (_isProcessing) return;

    for (final purchase in purchases) {
      // Avoid auto-retrying a purchase that failed in this session
      if (purchase.purchaseID != null && _failedPurchaseIds.contains(purchase.purchaseID)) {
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        if (!state.isLoading) state = const AsyncValue.loading();
      } else if (purchase.status == PurchaseStatus.error) {
        state = AsyncValue.error(purchase.error?.message ?? 'Purchase failed', StackTrace.current);
        await ref.read(iapRepositoryProvider).completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        _isProcessing = true;
        try {
          await _verifyAndUnlock(purchase);
        } finally {
          _isProcessing = false;
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        reset();
      }
    }
  }

  Future<void> _verifyAndUnlock(PurchaseDetails purchase) async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(currentUserProvider);
      if (user == null) {
        await ref.read(iapRepositoryProvider).completePurchase(purchase);
        reset();
        return;
      }

      // 1. Sync to Database
      await ref.read(authRepositoryProvider).markAsPaid(
        user.id,
        transactionId: purchase.purchaseID ?? 'iap_${DateTime.now().millisecondsSinceEpoch}',
        amount: AppConfig.unlockAmountKes.toDouble(),
      ).timeout(const Duration(seconds: 15));

      // 2. Complete Store Transaction
      await ref.read(iapRepositoryProvider).completePurchase(purchase);
      
      // 3. Refresh Profile
      ref.invalidate(userProfileProvider);
      _failedPurchaseIds.remove(purchase.purchaseID);
      await Future.delayed(const Duration(seconds: 1));
      
      state = const AsyncValue.data(null);
    } catch (e) {
      if (purchase.purchaseID != null) _failedPurchaseIds.add(purchase.purchaseID!);
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> buyUnlock(ProductDetails product) async {
    _failedPurchaseIds.clear(); // Clear failures on manual tap
    try {
      state = const AsyncValue.loading();
      await ref.read(iapRepositoryProvider).buyProduct(product);
    } catch (e) {
      if (e.toString().contains('already_owned')) {
        await restorePurchases();
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> restorePurchases() async {
    _failedPurchaseIds.clear(); // Clear failures on manual tap
    try {
      state = const AsyncValue.loading();
      await ref.read(iapRepositoryProvider).restorePurchases();
      await Future.delayed(const Duration(seconds: 5));
      if (mounted && state.isLoading) state = const AsyncValue.data(null);
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

final iapStateNotifierProvider = StateNotifierProvider<IapStateNotifier, AsyncValue<void>>((ref) => IapStateNotifier(ref));
