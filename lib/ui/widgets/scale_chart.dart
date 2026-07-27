import 'package:flutter/material.dart';
import '../../models/scale.dart';
import '../../models/note.dart';

/// 音阶图表（对应原 Swift ScaleChartView.swift）
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
      (n) => n.sharpName == selectedKey || n.flatName == selectedKey,
      orElse: () => NoteName.c,
    );
    final keySig = KeySignature(tonic, scaleType);
    final notes = keySig.notesInKey(octave: 4);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${keySig.displayName} 音阶',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List.generate(notes.length, (i) {
                final midi = notes[i];
                final name = NoteName.values[midi % 12];
                final degree = i + 1;
                return Chip(
                  label: Text(
                    '${ScaleDegree.values[i].roman} ${name.sharpName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.blueGrey.withAlpha(80),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
