import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/core/theme.dart';

/// Overlays (tooltips, menus, snack bars) render above the Scaffold and do
/// not inherit the text theme. If their styles lack the bundled family, the
/// web build falls back to Roboto and shows Chinese text as boxes.
void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    test('$name theme gives every overlay text style the bundled font', () {
      final styles = <String, TextStyle?>{
        'tooltip': theme.tooltipTheme.textStyle,
        'popup menu': theme.popupMenuTheme.textStyle,
        'snack bar': theme.snackBarTheme.contentTextStyle,
        'input label': theme.inputDecorationTheme.labelStyle,
        'floating label': theme.inputDecorationTheme.floatingLabelStyle,
        'dialog content': theme.dialogTheme.contentTextStyle,
        'body': theme.textTheme.bodyMedium,
      };
      for (final entry in styles.entries) {
        expect(entry.value?.fontFamily, isNotNull, reason: entry.key);
        expect(
          [AppTheme.sans, AppTheme.serif],
          contains(entry.value!.fontFamily),
          reason: entry.key,
        );
      }
    });
  }

  testWidgets('tooltip text renders with the bundled Chinese font', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: AppTheme.sans),
          child: child!,
        ),
        home: const Scaffold(
          body: Center(
            child: Tooltip(message: '只保留品记', child: Text('仅品记')),
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.text('仅品记')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final tip = tester.widget<Text>(find.text('只保留品记'));
    final effective = DefaultTextStyle.of(
      tester.element(find.text('只保留品记')),
    ).style.merge(tip.style);
    expect(effective.fontFamily, AppTheme.sans);
    await gesture.removePointer();
  });
}
