import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_dot_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: darkOceanTheme.toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

bool _hasIcon(List<FaIcon> icons, FaIconData target) =>
    icons.any((i) => i.icon?.codePoint == target.codePoint);

void main() {
  group('CycleDotRow', () {
    testWidgets('renders dot indicators without error', (tester) async {
      await tester.pumpWidget(
        _wrap(const CycleDotRow(totalCycles: 5, currentCycle: 1)),
      );
      expect(find.byType(CycleDotRow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows caretDown icon for deep-exhale cycles', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CycleDotRow(
            totalCycles: 6,
            currentCycle: 1,
            extendedExhaleInterval: 3,
          ),
        ),
      );
      final icons = tester.widgetList<FaIcon>(find.byType(FaIcon)).toList();
      expect(
        _hasIcon(icons, FontAwesomeIcons.arrowDown),
        isTrue,
        reason: 'deep-exhale cycles should show an arrowDown icon',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows caretUp icon for deep-inhale cycles', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CycleDotRow(
            totalCycles: 6,
            currentCycle: 1,
            extendedInhaleInterval: 3,
          ),
        ),
      );
      final icons = tester.widgetList<FaIcon>(find.byType(FaIcon)).toList();
      expect(
        _hasIcon(icons, FontAwesomeIcons.arrowUp),
        isTrue,
        reason: 'deep-inhale cycles should show an arrowUp icon',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows arrowsUpDown icon when both intervals share a cycle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CycleDotRow(
            totalCycles: 6,
            currentCycle: 1,
            extendedExhaleInterval: 3,
            extendedInhaleInterval: 2,
          ),
        ),
      );
      // Cycle 6 is divisible by both 3 and 2 → arrowsUpDown
      final icons = tester.widgetList<FaIcon>(find.byType(FaIcon)).toList();
      expect(
        _hasIcon(icons, FontAwesomeIcons.arrowsUpDown),
        isTrue,
        reason: 'cycle divisible by both intervals should show arrowsUpDown',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error when no intervals are set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const CycleDotRow(totalCycles: 10, currentCycle: 3)),
      );
      expect(find.byType(FaIcon), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
