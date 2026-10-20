import 'package:fittrack/main.dart';
import 'package:fittrack/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('тема FitTrack — Material 3 с палитрой из seed-цвета домена', () {
    final theme = buildFitTrackTheme();
    final expected = ColorScheme.fromSeed(seedColor: fitTrackSeedColor);

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, expected.primary);
    expect(theme.colorScheme.primaryContainer, expected.primaryContainer);
  });

  testWidgets('приложение применяет тему FitTrack', (tester) async {
    await tester.pumpWidget(const FitTrackApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'FitTrack');
    expect(
      app.theme!.colorScheme.primary,
      buildFitTrackTheme().colorScheme.primary,
    );
  });
}
