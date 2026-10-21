import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/audio/bloc/audio_bloc.dart';
import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:breathscape/features/audio/presentation/widgets/voice_mute_button.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioBloc extends MockBloc<AudioEvent, AudioState>
    implements AudioBloc {}

Widget _buildSubject(_MockAudioBloc bloc) => MaterialApp(
  theme: darkOceanTheme.toThemeData(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: BlocProvider<AudioBloc>.value(
      value: bloc,
      child: const VoiceMuteButton(),
    ),
  ),
);

Finder _faIcon(FaIconData icon) => find.byWidgetPredicate(
  (w) => w is FaIcon && w.icon?.codePoint == icon.codePoint,
);

void main() {
  late _MockAudioBloc bloc;

  setUp(() {
    bloc = _MockAudioBloc();
    when(() => bloc.state).thenReturn(const AudioState());
  });

  group('VoiceMuteButton', () {
    testWidgets('renders unmuted icon and tooltip initially', (tester) async {
      await tester.pumpWidget(_buildSubject(bloc));

      expect(_faIcon(FontAwesomeIcons.commentDots), findsOneWidget);
      expect(_faIcon(FontAwesomeIcons.commentSlash), findsNothing);
      expect(find.byTooltip('Voice cues on'), findsOneWidget);
    });

    testWidgets('switches to muted icon when state becomes muted', (
      tester,
    ) async {
      whenListen(
        bloc,
        Stream<AudioState>.fromIterable([const AudioState(isMuted: true)]),
        initialState: const AudioState(),
      );
      await tester.pumpWidget(_buildSubject(bloc));
      await tester.pump();

      expect(_faIcon(FontAwesomeIcons.commentSlash), findsOneWidget);
      expect(_faIcon(FontAwesomeIcons.commentDots), findsNothing);
      expect(find.byTooltip('Voice cues off'), findsOneWidget);
    });

    testWidgets('tap adds VoiceMuteToggled', (tester) async {
      await tester.pumpWidget(_buildSubject(bloc));

      await tester.tap(find.byType(IconButton));

      verify(() => bloc.add(const VoiceMuteToggled())).called(1);
    });
  });
}
