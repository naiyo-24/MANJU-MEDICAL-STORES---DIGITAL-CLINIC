import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_alert_item.dart';
import '../services/stock_alert_service.dart';
import 'counter_providers.dart';

class StockAlertNotifier extends AsyncNotifier<List<StockAlertItem>> {
  @override
  Future<List<StockAlertItem>> build() async {
    ref.watch(selectedShopIdProvider);
    return StockAlertService.fetchLowStockAlerts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => StockAlertService.fetchLowStockAlerts());
  }
}

final stockAlertProvider =
    AsyncNotifierProvider<StockAlertNotifier, List<StockAlertItem>>(() {
  return StockAlertNotifier();
});
