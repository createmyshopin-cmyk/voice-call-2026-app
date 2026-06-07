import 'package:flutter/material.dart';

/// Tap feedback: scale 1.0 → 0.96 → 1.0
class ScalePressedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final double pressedScale;

  const ScalePressedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.pressedScale = 0.96,
  });

  @override
  State<ScalePressedButton> createState() => _ScalePressedButtonState();
}

class _ScalePressedButtonState extends State<ScalePressedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _controller.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _controller.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => _controller.reverse() : null,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
