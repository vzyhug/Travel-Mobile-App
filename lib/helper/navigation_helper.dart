import 'package:flutter/material.dart';

/// Navigates to a new tab screen seamlessly using a smooth and fast FadeTransition.
/// This prevents layout flicker and simulates the experience of a single-page view-pager.
void navigateToTab(BuildContext context, Widget targetScreen) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
    ),
  );
}
