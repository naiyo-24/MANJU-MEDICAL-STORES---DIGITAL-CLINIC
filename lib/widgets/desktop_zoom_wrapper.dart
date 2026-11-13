import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/desktop_zoom_provider.dart';

/// Zoom is strictly enabled ONLY for the Windows desktop (.exe) build.
/// Disabled on Web, macOS, iOS, and Android.
bool get isZoomSupported => !kIsWeb && Platform.isWindows;

/// Global wrapper that scales components and typography without shrinking the viewport window.
/// Keeps the app pinned 100% edge-to-edge while adjusting UI density and text scale.
class DesktopZoomWrapper extends ConsumerWidget {
  final Widget child;

  const DesktopZoomWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isZoomSupported) {
      return child;
    }

    final zoom = ref.watch(desktopZoomProvider);

    // Map zoom scale (0.70 to 1.40) to Material VisualDensity (-3.0 to +3.0)
    // 0.70 zoom = -3.0 (ultra compact components)
    // 1.00 zoom =  0.0 (standard density)
    // 1.40 zoom = +3.0 (large comfortable components)
    final densityValue = ((zoom - 1.0) / 0.10).clamp(-3.0, 3.0);

    return CallbackShortcuts(
      bindings: {
        // Ctrl + / Cmd + (equals key)
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () {
          ref.read(desktopZoomProvider.notifier).zoomIn();
        },
        const SingleActivator(LogicalKeyboardKey.equal, meta: true): () {
          ref.read(desktopZoomProvider.notifier).zoomIn();
        },
        // Numpad Add
        const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): () {
          ref.read(desktopZoomProvider.notifier).zoomIn();
        },
        const SingleActivator(LogicalKeyboardKey.numpadAdd, meta: true): () {
          ref.read(desktopZoomProvider.notifier).zoomIn();
        },
        // Ctrl - / Cmd - (minus key)
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () {
          ref.read(desktopZoomProvider.notifier).zoomOut();
        },
        const SingleActivator(LogicalKeyboardKey.minus, meta: true): () {
          ref.read(desktopZoomProvider.notifier).zoomOut();
        },
        // Numpad Subtract
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): () {
          ref.read(desktopZoomProvider.notifier).zoomOut();
        },
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, meta: true): () {
          ref.read(desktopZoomProvider.notifier).zoomOut();
        },
        // Ctrl 0 / Cmd 0 (Reset to 100%)
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () {
          ref.read(desktopZoomProvider.notifier).resetZoom();
        },
        const SingleActivator(LogicalKeyboardKey.digit0, meta: true): () {
          ref.read(desktopZoomProvider.notifier).resetZoom();
        },
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true): () {
          ref.read(desktopZoomProvider.notifier).resetZoom();
        },
        const SingleActivator(LogicalKeyboardKey.numpad0, meta: true): () {
          ref.read(desktopZoomProvider.notifier).resetZoom();
        },
      },
      child: Focus(
        autofocus: true,
        child: Theme(
          data: Theme.of(context).copyWith(
            visualDensity: VisualDensity(
              horizontal: densityValue,
              vertical: densityValue,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Scales all typography, text, badges, and labels across all screens
              textScaler: TextScaler.linear(zoom),
            ),
            // The canvas remains 100% full width and height edge-to-edge
            child: child,
          ),
        ),
      ),
    );
  }
}
