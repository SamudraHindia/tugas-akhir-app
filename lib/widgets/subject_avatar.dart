import 'package:flutter/material.dart';

import '../core/subject_visual.dart';

class SubjectAvatar extends StatelessWidget {
  const SubjectAvatar({
    super.key,
    required this.mapel,
    this.size = 48,
    this.solid = false,
  });

  final String mapel;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final visual = SubjectVisual.forMapel(mapel);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid
            ? visual.color
            : visual.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        visual.icon,
        color: solid ? Colors.white : visual.color,
        size: size * 0.48,
      ),
    );
  }
}
