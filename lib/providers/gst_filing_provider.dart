import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gst_filing.dart';
import '../services/gst_filing_service.dart';

final gstFilingsProvider =
    AsyncNotifierProvider<GstFilingsNotifier, List<GstFiling>>(
  () => GstFilingsNotifier(),
);

class GstFilingsNotifier extends AsyncNotifier<List<GstFiling>> {
  @override
  Future<List<GstFiling>> build() async {
    return _fetchFilings();
  }

  Future<List<GstFiling>> _fetchFilings() async {
    return GstFilingService.getMyFilings();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFilings());
  }

  Future<void> deleteFiling(String id) async {
    await GstFilingService.deleteFiling(id);
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.where((filing) => filing.id != id).toList(),
    );
  }

  void addFiling(GstFiling filing) {
    final currentList = state.value ?? [];
    state = AsyncValue.data([filing, ...currentList]);
  }
}
