import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/counter_providers.dart';
import '../services/inventory_service.dart';

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  int _currentSkip = 0;
  final int _limit = 100;
  String? _lastSearchQuery;
  String? _lastStartDate;
  String? _lastEndDate;
  String? _lastCategoryId;
  String? _lastDistributorId;
  bool _hasMore = true;
  int _activeSearchSessionId = 0;

  bool get hasMore => _hasMore;
  int get activeSearchSessionId => _activeSearchSessionId;

  /// Invalidate any pending in-flight requests immediately
  void cancelPendingSearch() {
    _activeSearchSessionId++;
  }

  @override
  Future<List<InventoryItem>> build() async {
    ref.watch(selectedShopIdProvider);
    return _fetchInventory();
  }

  Future<void> loadInventory({
    String? searchQuery,
    String? startDate,
    String? endDate,
    String? categoryId,
    String? distributorId,
  }) async {
    _currentSkip = 0;
    _hasMore = true;
    _lastSearchQuery = searchQuery;
    _lastStartDate = startDate;
    _lastEndDate = endDate;
    _lastCategoryId = categoryId;
    _lastDistributorId = distributorId;

    final int currentSessionId = ++_activeSearchSessionId;

    try {
      final items = await _fetchInventory(
        searchQuery: searchQuery,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        distributorId: distributorId,
        skip: _currentSkip,
        limit: _limit,
      );
      // Guard against out-of-order race conditions: discard stale in-flight responses!
      if (currentSessionId != _activeSearchSessionId) return;
      state = AsyncData(List<InventoryItem>.from(items));
    } catch (e, st) {
      if (currentSessionId != _activeSearchSessionId) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    _currentSkip += _limit;

    final currentList = state.value ?? [];
    final int currentSessionId = _activeSearchSessionId;

    // Fetch next page
    final nextList = await _fetchInventory(
      searchQuery: _lastSearchQuery,
      startDate: _lastStartDate,
      endDate: _lastEndDate,
      categoryId: _lastCategoryId,
      distributorId: _lastDistributorId,
      skip: _currentSkip,
      limit: _limit,
    );

    if (currentSessionId != _activeSearchSessionId) return;

    if (nextList.length < _limit) {
      _hasMore = false;
    }

    // Append to existing
    state = AsyncValue.data([...currentList, ...nextList]);
  }

  Future<List<InventoryItem>> _fetchInventory({
    String? searchQuery,
    String? startDate,
    String? endDate,
    String? categoryId,
    String? distributorId,
    int skip = 0,
    int limit = 100,
  }) async {
    String? shopId = ref.read(selectedShopIdProvider);
    if (shopId == null) {
      try {
        shopId = await InventoryService.getShopId();
        if (shopId.isNotEmpty && ref.read(selectedShopIdProvider) != shopId) {
          // Delay state update to avoid 'setState() or markNeedsBuild() called during build'
          Future.microtask(() {
            if (ref.read(selectedShopIdProvider) != shopId) {
              ref.read(selectedShopIdProvider.notifier).updateShopId(shopId);
            }
          });
        }
      } catch (e) {
        return [];
      }
    }

    return await InventoryService.fetchInventory(
      shopId: shopId,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      distributorId: distributorId,
      skip: skip,
      limit: limit,
    );
  }
}
