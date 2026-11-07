import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Bold heading used above each dashboard section.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryDark,
      ),
    );
  }
}
