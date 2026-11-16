import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Membuat anak widget terasa "ditekan" dengan animasi skala ringan.
///
/// Memakai [Listener] agar tidak berebut gesture dengan [InkWell],
/// tombol, atau [PopupMenuButton] di dalamnya.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = 0.977,
    this.duration = const Duration(milliseconds: 110),
    this.enabled = true,
    this.haptic = false,
  });

  final Widget child;
  final double scale;
  final Duration duration;
  final bool enabled;
  final bool haptic;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _handleDown(PointerDownEvent event) {
    if (!widget.enabled || _pressed) return;
    setState(() => _pressed = true);
    if (widget.haptic) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleRelease([PointerEvent? event]) {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleDown,
      onPointerUp: _handleRelease,
      onPointerCancel: _handleRelease,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
