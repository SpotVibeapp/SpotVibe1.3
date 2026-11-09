import 'package:flutter/widgets.dart';

/// Wide-browser layout starts here. Galaxy Z Fold logical widths used by the
/// layout tests stay under this (the widest is about 891), so phones keep
/// the bottom bar and the single-column feed.
const double kWideLayoutBreakpoint = 960;

/// Centered column for the feed, event detail, and auth screens.
const double kWebContentMaxWidth = 1120;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;

/// How many event cards to place side by side. One column below [kWideLayoutBreakpoint].
int feedColumnCount(double screenWidth) {
  if (screenWidth >= 1400) return 3;
  if (screenWidth >= kWideLayoutBreakpoint) return 2;
  return 1;
}

/// Caps the width of [child] on a wide window and leaves phone layouts alone.
class WideContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const WideContent({
    super.key,
    required this.child,
    this.maxWidth = kWebContentMaxWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWideLayout(context)) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
