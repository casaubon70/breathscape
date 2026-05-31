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
            extendedExhaleCycles: {3, 6},
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
            extendedInhaleCycles: {3, 6},
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

    testWidgets('shows arrowsUpDown icon when a cycle has both types', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CycleDotRow(
            totalCycles: 6,
            currentCycle: 1,
            extendedExhaleCycles: {3, 6},
            extendedInhaleCycles: {2, 4, 6},
          ),
        ),
      );
      // Cycle 6 is in both sets → arrowsUpDown
      final icons = tester.widgetList<FaIcon>(find.byType(FaIcon)).toList();
      expect(
        _hasIcon(icons, FontAwesomeIcons.arrowsUpDown),
        isTrue,
        reason: 'cycle in both sets should show arrowsUpDown',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error when no extended cycles are set', (
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
