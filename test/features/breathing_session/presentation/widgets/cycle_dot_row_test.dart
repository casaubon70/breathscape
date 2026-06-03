import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_dot_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
  theme: darkOceanTheme.toThemeData(),
  home: Scaffold(body: child),
);

Widget _wrapW(Widget child, double width) => _wrap(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: child),
  ),
);

bool _hasIcon(List<FaIcon> icons, FaIconData target) =>
    icons.any((i) => i.icon?.codePoint == target.codePoint);

SessionSegment _seg(int cycleCount) =>
    SessionSegment(label: 'Main', cycleCount: cycleCount, cycleSpec: const []);

SessionSegment _named(String label, int cycleCount) =>
    SessionSegment(label: label, cycleCount: cycleCount, cycleSpec: const []);

Finder _paginatorDot(int index) => find.byKey(Key('cycle_dot_page_$index'));

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CycleDotRow', () {
    // ── rendering (unchanged) ─────────────────────────────────────────────

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
              SessionSegment(label: 'Warm Up', cycleCount: 3, cycleSpec: []),
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
        _wrap(CycleDotRow(segments: [_seg(2), _seg(3)], currentCycle: 1)),
      );
      expect(
        find.byWidgetPredicate((w) => w is ColoredBox && w.color.a > 0),
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
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'extended cycle indices are absolute across multiple segments',
      (tester) async {
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

    // ── paginator ─────────────────────────────────────────────────────────

    testWidgets('no paginator dots when all segments fit', (tester) async {
      // Two short segments fit easily in the default 800-wide test screen.
      await tester.pumpWidget(
        _wrap(
          CycleDotRow(
            segments: [_named('Warm Up', 3), _named('Cool Down', 3)],
            currentCycle: 1,
          ),
        ),
      );
      expect(_paginatorDot(0), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paginator appears when segments overflow width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapW(
          CycleDotRow(
            segments: [
              _named('Alpha', 3),
              _named('Beta', 3),
              _named('Gamma', 3),
            ],
            currentCycle: 1,
          ),
          100,
        ),
      );
      // One paginator dot per segment.
      expect(_paginatorDot(0), findsOneWidget);
      expect(_paginatorDot(1), findsOneWidget);
      expect(_paginatorDot(2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paginator dot count matches segment count', (tester) async {
      const segCount = 4;
      await tester.pumpWidget(
        _wrapW(
          CycleDotRow(
            segments: List.generate(segCount, (_) => _seg(3)),
            currentCycle: 1,
          ),
          100,
        ),
      );
      for (var i = 0; i < segCount; i++) {
        expect(_paginatorDot(i), findsOneWidget);
      }
      expect(_paginatorDot(segCount), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap paginator dot navigates to that segment', (tester) async {
      // 100 px fits only the first segment; paginator appears.
      await tester.pumpWidget(
        _wrapW(
          CycleDotRow(
            segments: [
              _named('Alpha', 3),
              _named('Beta', 3),
              _named('Gamma', 3),
            ],
            currentCycle: 1,
          ),
          100,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ALPHA'), findsOneWidget);

      // 3 px dashes are too small for hit-test geometry via tap(); invoke
      // the callback directly to verify navigation logic is wired correctly.
      tester
          .widget<GestureDetector>(
            find.descendant(
              of: _paginatorDot(1),
              matching: find.byType(GestureDetector),
            ),
          )
          .onTap!();
      await tester.pump();

      expect(find.text('BETA'), findsOneWidget);
      expect(find.text('ALPHA'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('auto-navigates to segment of active dot on cycle change', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapW(
          CycleDotRow(
            segments: [_named('Warm', 3), _named('Main', 3), _named('Cool', 3)],
            currentCycle: 1,
          ),
          100,
        ),
      );
      expect(find.text('WARM'), findsOneWidget);

      // Cycle 4 belongs to the second segment (Main).
      await tester.pumpWidget(
        _wrapW(
          CycleDotRow(
            segments: [_named('Warm', 3), _named('Main', 3), _named('Cool', 3)],
            currentCycle: 4,
          ),
          100,
        ),
      );
      await tester.pump();

      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('WARM'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
