import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/disclaimer/bloc/disclaimer_bloc.dart';
import 'package:breathscape/features/disclaimer/presentation/disclaimer_page.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDisclaimerBloc extends MockBloc<DisclaimerEvent, DisclaimerState>
    implements DisclaimerBloc {}

Widget _buildSubject(_MockDisclaimerBloc bloc) => MaterialApp(
  theme: darkOceanTheme.toThemeData(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BlocProvider<DisclaimerBloc>.value(
    value: bloc,
    child: const DisclaimerPage(),
  ),
);

void main() {
  late _MockDisclaimerBloc bloc;

  setUp(() {
    bloc = _MockDisclaimerBloc();
    when(
      () => bloc.state,
    ).thenReturn(const DisclaimerState(status: DisclaimerStatus.notAccepted));
  });

  group('DisclaimerPage', () {
    testWidgets('renders disclaimer title', (tester) async {
      await tester.pumpWidget(_buildSubject(bloc));
      await tester.pump();
      expect(find.text('Important Notice'), findsOneWidget);
    });

    testWidgets('renders accept button', (tester) async {
      await tester.pumpWidget(_buildSubject(bloc));
      await tester.pump();
      expect(find.text('I Agree'), findsOneWidget);
    });

    testWidgets('tapping accept button adds DisclaimerAccepted', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(bloc));
      await tester.pump();
      await tester.tap(find.text('I Agree'));
      verify(() => bloc.add(const DisclaimerAccepted())).called(1);
    });
  });
}
