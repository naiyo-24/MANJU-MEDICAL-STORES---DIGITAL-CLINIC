import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manufacturer.dart';
import '../services/manufacturer_service.dart';

final manufacturerServiceProvider =
    Provider<ManufacturerService>((ref) => ManufacturerService());

class ManufacturerNotifier extends AsyncNotifier<List<Manufacturer>> {
  @override
  FutureOr<List<Manufacturer>> build() async {
    return _fetchManufacturers();
  }

  Future<List<Manufacturer>> _fetchManufacturers({String? search}) async {
    try {
      final service = ref.read(manufacturerServiceProvider);
      return await service.getManufacturers(search: search);
    } catch (e, st) {
      debugPrint('ManufacturerNotifier Error: $e\n$st');
      return [];
    }
  }

  Future<Manufacturer?> addManufacturer({
    required String name,
    String? shortCode,
  }) async {
    try {
      final service = ref.read(manufacturerServiceProvider);
      final newMfg = await service.addManufacturer(
        name: name,
        shortCode: shortCode,
      );

      // Optimistically update list in state
      if (state.hasValue) {
        final current = state.value!;
        // Ensure no duplicate if already present
        final updated = [
          ...current.where((m) => m.id != newMfg.id),
          newMfg,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        state = AsyncValue.data(updated);
      } else {
        state = AsyncValue.data([newMfg]);
      }
      return newMfg;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateManufacturer(
    String id, {
    String? name,
    String? shortCode,
  }) async {
    try {
      final service = ref.read(manufacturerServiceProvider);
      final updatedMfg = await service.updateManufacturer(
        id,
        name: name,
        shortCode: shortCode,
      );

      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!
              .map((m) => m.id == id ? updatedMfg : m)
              .toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteManufacturer(String id) async {
    try {
      final service = ref.read(manufacturerServiceProvider);
      await service.deleteManufacturer(id);

      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((m) => m.id != id).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchManufacturers());
  }
}

final manufacturerProvider =
    AsyncNotifierProvider<ManufacturerNotifier, List<Manufacturer>>(() {
  return ManufacturerNotifier();
});
