import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/counter_notifier.dart';
import '../notifiers/customer_notifier.dart';
import '../notifiers/inventory_notifier.dart';
import '../services/inventory_service.dart';
import '../notifiers/doctor_notifier.dart';
import '../services/doctor_service.dart';
import '../notifiers/accounts_notifier.dart';
import '../notifiers/history_notifier.dart';
import '../notifiers/settings_notifier.dart';

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Map<String, dynamic>>(() {
  return SettingsNotifier();
});

final historyProvider = AsyncNotifierProvider<HistoryNotifier, HistoryState>(() {
  return HistoryNotifier();
});

final shopProvider = AsyncNotifierProvider<ShopNotifier, List<Map<String, dynamic>>>(() {
  return ShopNotifier();
});

final customerProvider = AsyncNotifierProvider<CustomerNotifier, List<Map<String, dynamic>>>(() {
  return CustomerNotifier();
});

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(() {
  return InventoryNotifier();
});

final doctorProvider = AsyncNotifierProvider<DoctorNotifier, List<Doctor>>(() {
  return DoctorNotifier();
});

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, AccountsState>(() {
  return AccountsNotifier();
});

