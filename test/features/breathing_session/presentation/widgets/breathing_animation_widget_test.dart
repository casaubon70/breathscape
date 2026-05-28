import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: darkOceanTheme.toThemeData(),
  home: Scaffold(body: child),
);

const _defaultWidget = BreathingAnimationWidget(
  fillLevel: 0.5,
  isAnimating: false,
  circleScale: 1,
  circleOpacity: 1,
  circleBottomScale: 1,
  circleBottomOpacity: 1,
);

void main() {
  group('BreathingAnimationWidget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(const SizedBox(width: 120, child: _defaultWidget)),
      );
      expect(find.byType(BreathingAnimationWidget), findsOneWidget);
    });

    testWidgets('accepts fillLevel 0.0', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 120,
            child: BreathingAnimationWidget(
              fillLevel: 0,
              isAnimating: false,
              circleScale: 1,
              circleOpacity: 1,
              circleBottomScale: 1,
              circleBottomOpacity: 1,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts fillLevel 1.0', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 120,
            child: BreathingAnimationWidget(
              fillLevel: 1,
              isAnimating: true,
              circleScale: 1,
              circleOpacity: 1,
              circleBottomScale: 1,
              circleBottomOpacity: 1,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps fillLevel above 1.0 without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 120,
            child: BreathingAnimationWidget(
              fillLevel: 1.5,
              isAnimating: false,
              circleScale: 1,
              circleOpacity: 1,
              circleBottomScale: 1,
              circleBottomOpacity: 1,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('all circle params at 0.0 render without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 120,
            child: BreathingAnimationWidget(
              fillLevel: 1,
              isAnimating: true,
              circleScale: 0,
              circleOpacity: 0,
              circleBottomScale: 0,
              circleBottomOpacity: 0,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
