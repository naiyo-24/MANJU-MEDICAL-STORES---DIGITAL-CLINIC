import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;

  final PreferredSizeWidget? appBar;

  final Widget? desktopSidebar;

  final Widget? mobileDrawer;

  final Widget? mobileBottomNavigation;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.desktopSidebar,
    this.mobileDrawer,
    this.mobileBottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // MOBILE
    if (width < 600) {
      return Scaffold(
        appBar: appBar,
        drawer: mobileDrawer,
        body: SafeArea(
          child: body,
        ),
        bottomNavigationBar: mobileBottomNavigation,
      );
    }

    // TABLET
    if (width < 1024) {
      return Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: body,
        ),
      );
    }

    // DESKTOP / LARGE DESKTOP
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktopSidebar != null) desktopSidebar!,

            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}
