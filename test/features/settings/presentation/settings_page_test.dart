import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/settings/presentation/settings_page.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildSubject() => MaterialApp(
  theme: darkOceanTheme.toThemeData(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  group('SettingsPage', () {
    testWidgets('renders title and close button', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping close pops the page', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
