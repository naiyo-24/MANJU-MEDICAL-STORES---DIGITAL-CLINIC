import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/desktop_zoom_provider.dart';

/// Flag to allow browser/macOS testing. In production, can be set to false.
const bool kEnableZoomForTesting = true;

bool get isZoomSupported =>
    kEnableZoomForTesting || (!kIsWeb && Platform.isWindows);

/// Global wrapper that applies proportional UI zoom and handles Ctrl +/- hotkeys
class DesktopZoomWrapper extends ConsumerWidget {
  final Widget child;

  const DesktopZoomWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isZoomSupported) {
      return child;
    }

    final zoom = ref.watch(desktopZoomProvider);

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // When zoom is default 1.0, render normally
            if ((zoom - 1.0).abs() < 0.001) {
              return child;
            }

            final virtualWidth = constraints.maxWidth / zoom;
            final virtualHeight = constraints.maxHeight / zoom;

            return ClipRect(
              child: Transform.scale(
                scale: zoom,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: virtualWidth,
                  height: virtualHeight,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

