import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inventory_service.dart';

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  int _currentSkip = 0;
  final int _limit = 100;
  String? _lastSearchQuery;
  String? _lastStartDate;
  String? _lastEndDate;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<InventoryItem>> build() async {
    return _fetchInventory();
  }

  Future<void> loadInventory({String? searchQuery, String? startDate, String? endDate}) async {
    _currentSkip = 0;
    _hasMore = true;
    _lastSearchQuery = searchQuery;
    _lastStartDate = startDate;
    _lastEndDate = endDate;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInventory(
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      skip: _currentSkip,
      limit: _limit,
    ));
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    
    _currentSkip += _limit;
    
    final currentList = state.value ?? [];
    
    // Fetch next page
    final nextList = await _fetchInventory(
      searchQuery: _lastSearchQuery,
      startDate: _lastStartDate,
      endDate: _lastEndDate,
      skip: _currentSkip,
      limit: _limit,
    );

    if (nextList.length < _limit) {
      _hasMore = false;
    }

    // Append to existing
    state = AsyncValue.data([...currentList, ...nextList]);
  }

  Future<List<InventoryItem>> _fetchInventory({String? searchQuery, String? startDate, String? endDate, int skip = 0, int limit = 100}) async {
    return await InventoryService.fetchInventory(
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      skip: skip,
      limit: limit,
    );
  }
}
