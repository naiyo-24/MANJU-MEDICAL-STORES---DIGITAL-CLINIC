import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/counter_notifier.dart';
import '../services/shop_service.dart';

final shopProvider = AsyncNotifierProvider<ShopNotifier, List<Map<String, dynamic>>>(() {
  return ShopNotifier();
});
