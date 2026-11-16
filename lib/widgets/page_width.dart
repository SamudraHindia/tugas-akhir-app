import 'package:flutter/material.dart';

/// Membatasi lebar konten agar tetap nyaman dibaca di layar besar.
class PageWidth extends StatelessWidget {
  const PageWidth({
    super.key,
    required this.child,
    this.maxWidth = 980,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
