import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static bool isMobile(BuildContext context) {
    return width(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    final w = width(context);

    return w >= 600 && w < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return width(context) >= 1024;
  }

  static bool isLargeDesktop(BuildContext context) {
    return width(context) >= 1440;
  }

  static bool isMobileOrTablet(BuildContext context) {
    return width(context) < 1024;
  }

  static bool isTabletOrDesktop(BuildContext context) {
    return width(context) >= 600;
  }

  static double horizontalPadding(BuildContext context) {
    final w = width(context);

    if (w < 600) {
      return 12;
    }

    if (w < 1024) {
      return 20;
    }

    if (w < 1440) {
      return 28;
    }

    return 40;
  }

  static double spacing(BuildContext context) {
    final w = width(context);

    if (w < 600) {
      return 12;
    }

    if (w < 1024) {
      return 16;
    }

    return 20;
  }
}

class ResponsiveSplitView extends StatelessWidget {
  final Widget leftPane;
  final Widget rightPane;
  final int leftFlex;
  final int rightFlex;
  final bool showRightPane;

  const ResponsiveSplitView({
    super.key,
    required this.leftPane,
    required this.rightPane,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.showRightPane = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop =
        Responsive.isDesktop(context) || Responsive.isTablet(context);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: leftFlex, child: leftPane),
          if (showRightPane) const SizedBox(width: 24),
          if (showRightPane) Expanded(flex: rightFlex, child: rightPane),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            leftPane,
            if (showRightPane) const SizedBox(height: 24),
            if (showRightPane) rightPane,
          ],
        ),
      );
    }
  }
}
