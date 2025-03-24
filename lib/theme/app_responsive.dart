import 'package:flutter/material.dart';

/// A utility class that provides responsive sizing methods and device type detection
class AppResponsive {
  static const double _mobileBreakpoint = 375;
  static const double _tabletBreakpoint = 768;
  static const double _desktopBreakpoint = 1024;

  // iPhone 16 Pro Max dimensions for reference
  static const double iphone16ProMaxWidth = 430;
  static const double iphone16ProMaxHeight = 932;

  /// Returns true if the current device has a screen width that classifies it as a mobile device
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < _mobileBreakpoint;
  }

  /// Returns true if the current device has a screen width that classifies it as a small mobile device
  static bool isSmallMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 350;
  }

  /// Returns true if the current device has a screen width that classifies it as a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _desktopBreakpoint;
  }

  /// Returns true if the current device has a screen width that classifies it as a desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _desktopBreakpoint;
  }

  /// Get adaptive value for different screen sizes based on iPhone 16 Pro Max reference
  static double getAdaptiveValue({
    required BuildContext context,
    required double defaultValue,
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    // Calculate a scale factor relative to iPhone 16 Pro Max width
    final scaleFactor = width / iphone16ProMaxWidth;

    // Ensure we're not making things too small on small devices
    final adjustedScaleFactor = scaleFactor < 0.65 ? 0.65 : scaleFactor;

    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    if (isMobile(context) && mobile != null) return mobile;

    // For standard adaptivity, scale based on screen width relative to iPhone 16 Pro Max
    return defaultValue * adjustedScaleFactor;
  }

  /// Get adaptive font size
  static double getAdaptiveFontSize(
    BuildContext context,
    double fontSize, {
    double? minFontSize,
  }) {
    final adaptiveSize = getAdaptiveValue(
      context: context,
      defaultValue: fontSize,
    );

    // Ensure text doesn't get too small to read
    if (minFontSize != null && adaptiveSize < minFontSize) {
      return minFontSize;
    }

    return adaptiveSize;
  }

  /// Get adaptive padding
  static EdgeInsets getAdaptivePadding({
    required BuildContext context,
    required EdgeInsets defaultPadding,
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
  }) {
    if (isDesktop(context) && desktopPadding != null) return desktopPadding;
    if (isTablet(context) && tabletPadding != null) return tabletPadding;
    if (isMobile(context) && mobilePadding != null) return mobilePadding;

    final scale = getAdaptiveValue(context: context, defaultValue: 1.0);

    return EdgeInsets.fromLTRB(
      defaultPadding.left * scale,
      defaultPadding.top * scale,
      defaultPadding.right * scale,
      defaultPadding.bottom * scale,
    );
  }

  /// Get adaptive spacing
  static double getAdaptiveSpacing(BuildContext context, double spacing) {
    return getAdaptiveValue(context: context, defaultValue: spacing);
  }

  /// Get adaptive card width (for grids)
  static double getAdaptiveCardWidth(
    BuildContext context, {
    double defaultWidth = 180,
  }) {
    final width = MediaQuery.of(context).size.width;

    // Calculate how many cards should fit per row
    int cardsPerRow;
    if (width < 400) {
      cardsPerRow = 2; // Small mobile: 2 cards per row
    } else if (width < 700) {
      cardsPerRow = 3; // Mobile/small tablet: 3 cards per row
    } else if (width < 1100) {
      cardsPerRow = 4; // Tablet: 4 cards per row
    } else {
      cardsPerRow = 5; // Desktop: 5 cards per row
    }

    // Account for padding on the sides
    final padding = width * 0.05; // 5% of screen width for padding
    final availableWidth = width - (padding * 2);
    final cardSpacing = 10.0; // Space between cards

    // Calculate the width of each card
    return (availableWidth - (cardSpacing * (cardsPerRow - 1))) / cardsPerRow;
  }
}
