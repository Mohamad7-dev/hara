import 'package:flutter/material.dart';

/// مؤشر تحميل بصور الخطوط البيضاء (GIF) — يُستخدم بدل CircularProgressIndicator.
class HaraLoader extends StatelessWidget {
  const HaraLoader({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/loading_icon.gif',
      width: size,
      height: size,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}
