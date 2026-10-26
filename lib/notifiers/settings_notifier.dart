import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shop_settings_service.dart';
import '../utils/pdf_generator.dart';
import '../providers/counter_providers.dart';

class SettingsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    ref.watch(selectedShopIdProvider);
    return ShopSettingsService.getSettings();
  }

  Future<void> reloadSettings() async {
    PdfGenerator.clearImageCache();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ShopSettingsService.getSettings());
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await ShopSettingsService.updateSettings(data);
    PdfGenerator.clearImageCache();
    await reloadSettings();
  }
}
