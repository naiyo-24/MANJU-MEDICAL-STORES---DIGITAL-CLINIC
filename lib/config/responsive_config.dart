import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveConfig {
  ResponsiveConfig._();

  static const List<Breakpoint> breakpoints = [
    Breakpoint(
      start: 0,
      end: 599,
      name: MOBILE,
    ),

    Breakpoint(
      start: 600,
      end: 1023,
      name: TABLET,
    ),

    Breakpoint(
      start: 1024,
      end: 1439,
      name: DESKTOP,
    ),

    Breakpoint(
      start: 1440,
      end: double.infinity,
      name: 'LARGE_DESKTOP',
    ),
  ];
}
