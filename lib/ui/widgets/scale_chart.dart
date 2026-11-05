import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/note.dart';
import '../../models/scale.dart';

/// The notes of the selected key with their degree relative to the tonic.
class ScaleChartWidget extends StatelessWidget {
  final String selectedKey;
  final ScaleType scaleType;

  /// Without the card and heading, for use inside another panel.
  final bool embedded;

  const ScaleChartWidget({
    super.key,
    required this.selectedKey,
    required this.scaleType,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final tonic = NoteName.values.firstWhere(
      (note) => note.sharpName == selectedKey || note.flatName == selectedKey,
      orElse: () => NoteName.c,
    );
    final keySig = KeySignature(tonic, scaleType);
    final notes = keySig.notesInKey(octave: 4);

    final chips = Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (var index = 0; index < notes.length; index++)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${keySig.degreeLabel(notes[index]) ?? ''} ',
                  style: TextStyle(
                    color: index == 0 ? c.accent : c.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: NoteName.values[notes[index] % 12].sharpName,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (embedded) return chips;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(keySig.displayName, style: context.text.titleMedium),
            const SizedBox(height: 10),
            chips,
          ],
        ),
      ),
    );
  }
}
