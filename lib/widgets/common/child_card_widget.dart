import 'package:flutter/material.dart';

/// A reusable card widget that wraps its child with consistent styling.
///
/// This widget provides a standardized card appearance with customizable
/// margin and padding, used throughout the app to maintain visual consistency.
class ChildCardWidget extends StatelessWidget {
  /// The widget to display inside the card.
  final Widget child;

  /// The margin around the card.
  final EdgeInsetsGeometry margin;

  /// The padding inside the card.
  final EdgeInsetsGeometry padding;

  /// Creates a ChildCardWidget.
  ///
  /// The [child] parameter is required and specifies the widget to display inside the card.
  /// The [margin] parameter defaults to 8 pixels on top, left, and right.
  /// The [padding] parameter defaults to 8 pixels on all sides.
  const ChildCardWidget({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(top: 8, left: 8, right: 8),
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: margin,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
