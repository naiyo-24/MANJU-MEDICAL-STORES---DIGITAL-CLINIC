import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing global desktop/app zoom level using Riverpod 3 Notifier
final desktopZoomProvider = NotifierProvider<DesktopZoomNotifier, double>(() {
  return DesktopZoomNotifier();
});

class DesktopZoomNotifier extends Notifier<double> {
  static const String _prefKey = 'desktop_zoom_level';
  static const double minZoom = 0.70; // 70%
  static const double maxZoom = 1.40; // 140%
  static const double step = 0.05; // 5% per click

  @override
  double build() {
    _loadSavedZoom();
    return 1.0;
  }

  Future<void> _loadSavedZoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedZoom = prefs.getDouble(_prefKey);
      if (savedZoom != null && savedZoom >= minZoom && savedZoom <= maxZoom) {
        state = double.parse(savedZoom.toStringAsFixed(2));
      }
    } catch (_) {}
  }

  Future<void> _persistZoom(double zoom) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKey, zoom);
    } catch (_) {}
  }

  void zoomIn() {
    if (state < maxZoom) {
      final next = (state + step).clamp(minZoom, maxZoom);
      state = double.parse(next.toStringAsFixed(2));
      _persistZoom(state);
    }
  }

  void zoomOut() {
    if (state > minZoom) {
      final prev = (state - step).clamp(minZoom, maxZoom);
      state = double.parse(prev.toStringAsFixed(2));
      _persistZoom(state);
    }
  }

  void resetZoom() {
    state = 1.0;
    _persistZoom(1.0);
  }

  void setZoom(double zoom) {
    final clamped = zoom.clamp(minZoom, maxZoom);
    state = double.parse(clamped.toStringAsFixed(2));
    _persistZoom(state);
  }
}
