import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
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

SessionSegment _seg(int cycleCount) =>
    SessionSegment(label: 'Main', cycleCount: cycleCount, cycleSpec: const []);

void main() {
  group('CycleDotRow', () {
    testWidgets('renders dot indicators without error', (tester) async {
      await tester.pumpWidget(
        _wrap(CycleDotRow(segments: [_seg(5)], currentCycle: 1)),
      );
      expect(find.byType(CycleDotRow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows segment label in uppercase', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CycleDotRow(
            segments: [
              SessionSegment(
                label: 'Warm Up',
                cycleCount: 3,
                cycleSpec: [],
              ),
            ],
            currentCycle: 1,
          ),
        ),
      );
      expect(find.text('WARM UP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a divider between two segments', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleDotRow(
            segments: [_seg(2), _seg(3)],
            currentCycle: 1,
          ),
        ),
      );
      // The divider is the only non-transparent ColoredBox in the tree.
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color.a > 0,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows caretDown icon for deep-exhale cycles', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleDotRow(
            segments: [_seg(6)],
            currentCycle: 1,
            extendedExhaleCycles: const {3, 6},
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
          CycleDotRow(
            segments: [_seg(6)],
            currentCycle: 1,
            extendedInhaleCycles: const {3, 6},
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
          CycleDotRow(
            segments: [_seg(6)],
            currentCycle: 1,
            extendedExhaleCycles: const {3, 6},
            extendedInhaleCycles: const {2, 4, 6},
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
        _wrap(CycleDotRow(segments: [_seg(10)], currentCycle: 3)),
      );
      expect(find.byType(FaIcon), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'extended cycle indices are absolute across multiple segments',
      (tester) async {
        // Segment 1: cycles 1-2, Segment 2: cycles 3-5
        // extendedExhale on cycle 4 (in second segment)
        await tester.pumpWidget(
          _wrap(
            CycleDotRow(
              segments: [_seg(2), _seg(3)],
              currentCycle: 1,
              extendedExhaleCycles: const {4},
            ),
          ),
        );
        final icons = tester.widgetList<FaIcon>(find.byType(FaIcon)).toList();
        expect(
          _hasIcon(icons, FontAwesomeIcons.arrowDown),
          isTrue,
          reason: 'cycle 4 in second segment should show arrowDown',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
