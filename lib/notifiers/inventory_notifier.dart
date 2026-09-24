import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inventory_service.dart';

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    return _fetchInventory();
  }

  Future<void> loadInventory({String? searchQuery, String? startDate, String? endDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInventory(
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    ));
  }

  Future<List<InventoryItem>> _fetchInventory({String? searchQuery, String? startDate, String? endDate}) async {
    return await InventoryService.fetchInventory(
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
