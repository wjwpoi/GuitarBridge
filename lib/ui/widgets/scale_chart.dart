import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/note.dart';
import '../../models/scale.dart';

class ScaleChartWidget extends StatelessWidget {
  final String selectedKey;
  final ScaleType scaleType;

  const ScaleChartWidget({
    super.key,
    required this.selectedKey,
    required this.scaleType,
  });

  @override
  Widget build(BuildContext context) {
    final tonic = NoteName.values.firstWhere(
      (note) => note.sharpName == selectedKey || note.flatName == selectedKey,
      orElse: () => NoteName.c,
    );
    final keySig = KeySignature(tonic, scaleType);
    final notes = keySig.notesInKey(octave: 4);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 17, 20, 19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha(14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    size: 17,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    keySig.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${notes.length} 个音级',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < notes.length; index++)
                  _scaleNote(
                    degree: ScaleDegree.values[index].roman,
                    note: NoteName.values[notes[index] % 12].sharpName,
                    isTonic: index == 0,
                  ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: isTonic ? color.withAlpha(20) : AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: isTonic ? color : AppTheme.outlineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            degree,
            style: TextStyle(
              color: isTonic ? color : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 7),
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
