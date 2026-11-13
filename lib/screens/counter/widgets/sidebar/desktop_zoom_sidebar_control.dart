import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/desktop_zoom_provider.dart';
import '../../../../utils/responsive.dart';
import '../../../../widgets/desktop_zoom_wrapper.dart';

/// Sidebar zoom controller matching: 🔍 Zoom 100%   — 100% +
/// Built with AnimatedCrossFade and horizontal scroll guard to eliminate RenderFlex overflow.
class DesktopZoomSidebarControl extends ConsumerWidget {
  final bool isExpanded;

  const DesktopZoomSidebarControl({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isZoomSupported) {
      return const SizedBox.shrink();
    }

    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zoom = ref.watch(desktopZoomProvider);
    final percentText = '${(zoom * 100).round()}%';

    final textColor = isDark ? Colors.grey[200] : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);
    final primaryGreen = const Color(0xFF166534);

    return Container(
      width: isDesktop ? (isExpanded ? 228 : 48) : double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (zoom - 1.0).abs() > 0.01
              ? primaryGreen.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: isExpanded
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        alignment: Alignment.centerLeft,

        // First Child: Expanded state with horizontal scroll guard
        firstChild: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            width: isDesktop ? 226 : null,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: 🔍 Zoom
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zoom',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Right side controls: —  100%  +
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom Out Button (—)
                    InkWell(
                      onTap: zoom > DesktopZoomNotifier.minZoom
                          ? () => ref.read(desktopZoomProvider.notifier).zoomOut()
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        child: Icon(
                          Icons.remove,
                          size: 15,
                          color: zoom > DesktopZoomNotifier.minZoom
                              ? textColor
                              : Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                    ),

                    // Percentage Badge (Clickable to Reset)
                    Tooltip(
                      message: 'Click to reset to 100%',
                      child: InkWell(
                        onTap: () => ref.read(desktopZoomProvider.notifier).resetZoom(),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: (zoom - 1.0).abs() > 0.01
                                ? primaryGreen.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            percentText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: (zoom - 1.0).abs() > 0.01
                                  ? primaryGreen
                                  : subtitleColor,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Zoom In Button (+)
                    InkWell(
                      onTap: zoom < DesktopZoomNotifier.maxZoom
                          ? () => ref.read(desktopZoomProvider.notifier).zoomIn()
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        child: Icon(
                          Icons.add,
                          size: 15,
                          color: zoom < DesktopZoomNotifier.maxZoom
                              ? textColor
                              : Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Second Child: Collapsed compact state (48x48 icon)
        secondChild: Tooltip(
          message: 'Zoom: $percentText\nClick to Reset (100%)',
          child: InkWell(
            onTap: () => ref.read(desktopZoomProvider.notifier).resetZoom(),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: (zoom - 1.0).abs() > 0.01 ? primaryGreen : subtitleColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
