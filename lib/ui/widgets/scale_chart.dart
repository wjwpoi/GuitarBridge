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
    final tonic = NoteName.values.firstWhere(
      (note) => note.sharpName == selectedKey || note.flatName == selectedKey,
      orElse: () => NoteName.c,
    );
    final keySig = KeySignature(tonic, scaleType);
    final notes = keySig.notesInKey(octave: 4);

    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var index = 0; index < notes.length; index++)
          _scaleNote(
            degree: keySig.degreeLabel(notes[index]) ?? '',
            note: NoteName.values[notes[index] % 12].sharpName,
            isTonic: index == 0,
          ),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: chips,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    keySig.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${notes.length} 个音',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            chips,
          ],
        ),
      ),
    );
  }

  Widget _scaleNote({
    required String degree,
    required String note,
    required bool isTonic,
  }) {
    final color = isTonic ? AppTheme.primaryColor : AppTheme.secondaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isTonic ? color.withAlpha(20) : AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: isTonic ? color : AppTheme.outlineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            degree,
            style: TextStyle(
              color: isTonic ? color : AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            note,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
