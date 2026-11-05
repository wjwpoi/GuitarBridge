import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The bundled Chinese fonts are subsetted to the characters the app uses.
/// If this fails, run `python3 tool/subset_fonts.py ...` (see the script's
/// header) so new text does not fall back to a network font.
void main() {
  test('bundled font subset covers every character used in lib/', () {
    final glyphs = File(
      'assets/fonts/glyphs.txt',
    ).readAsStringSync().runes.toSet();
    final missing = <String, Set<String>>{};
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      for (final rune in file.readAsStringSync().runes) {
        if (rune <= 0x7F || rune == 0xFEFF) continue;
        final char = String.fromCharCode(rune);
        if (char.trim().isEmpty) continue;
        if (!glyphs.contains(rune)) {
          missing.putIfAbsent(file.path, () => {}).add(char);
        }
      }
    }
    expect(missing, isEmpty, reason: 'Characters missing from the subset');
  });

  test('pubspec registers the bundled font families', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: NotoSansSC'));
    expect(pubspec, contains('family: NotoSerifSC'));
    for (final asset in [
      'NotoSansSC-Regular.ttf',
      'NotoSansSC-Medium.ttf',
      'NotoSansSC-SemiBold.ttf',
      'NotoSerifSC-SemiBold.ttf',
    ]) {
      expect(File('assets/fonts/$asset').existsSync(), isTrue, reason: asset);
    }
  });
}
