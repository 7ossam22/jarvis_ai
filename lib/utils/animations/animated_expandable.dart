import 'package:flutter/material.dart';

class AnimatedExpandable extends StatelessWidget {
  final bool isExpanded;
  final Widget child;
  final Duration duration;

  const AnimatedExpandable({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOutBack,
      alignment: Alignment.topCenter,
      child: isExpanded ? child : const SizedBox.shrink(),
    );
  }
}
