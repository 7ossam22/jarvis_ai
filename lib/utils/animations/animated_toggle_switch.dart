import 'package:flutter/material.dart';

class AnimatedToggleSwitch extends StatelessWidget {
  final bool isToggled;
  final ValueChanged<bool> onChanged;
  final bool disabled; // New parameter
  final Color? activeColor;
  final Color inactiveColor;
  final Duration duration;

  const AnimatedToggleSwitch({
    super.key,
    required this.isToggled,
    required this.onChanged,
    this.disabled = false, // Defaulted to false
    this.activeColor,
    this.inactiveColor = const Color(0xFFE2E8F0),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // If disabled, we pass null to ignore the tap event
      onTap: disabled ? null : () => onChanged(!isToggled),
      child: Opacity(
        // Reduce opacity when disabled to provide visual feedback
        opacity: disabled ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: duration,
          width: 56,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color:
            isToggled
                ? (activeColor ?? Theme.of(context).primaryColor)
                : inactiveColor,
            // Optional: add a border when disabled if preferred
            border: Border.all(
              color:
              disabled
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeOutBack,
                left: isToggled ? 26 : 2,
                right: isToggled ? 2 : 26,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
