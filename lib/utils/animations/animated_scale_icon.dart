import 'package:flutter/material.dart';

class AnimatedScaleIcon extends StatelessWidget {
  final bool isToggled;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color? activeColor;
  final Color inactiveColor;
  final double size;
  final Duration duration;

  const AnimatedScaleIcon({
    super.key,
    required this.isToggled,
    required this.activeIcon,
    required this.inactiveIcon,
    this.activeColor,
    this.inactiveColor = const Color(0xFF64748B),
    this.size = 32,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Icon(
        isToggled ? activeIcon : inactiveIcon,
        key: ValueKey<bool>(isToggled),
        color:
        isToggled
            ? (activeColor ?? Theme.of(context).primaryColor)
            : inactiveColor,
        size: size,
      ),
    );
  }
}
