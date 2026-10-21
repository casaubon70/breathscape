import 'package:breathscape/features/audio/bloc/audio_bloc.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:breathscape/features/audio/presentation/widgets/voice_mute_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_driver.dart';

Finder _faIcon(FaIconData icon) => find.byWidgetPredicate(
  (w) => w is FaIcon && w.icon?.codePoint == icon.codePoint,
);

AudioState _audioState(WidgetTester tester) =>
    tester.element(find.byType(VoiceMuteButton)).read<AudioBloc>().state;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Audio', () {
    testWidgets('Play lädt Sprachansage → Stummschalten → Pause', (
      tester,
    ) async {
      await launchToSessionPage(tester);
      expect(_audioState(tester).status, AudioStatus.idle);
      expect(_faIcon(FontAwesomeIcons.commentDots), findsOneWidget);

      // Playing only flips once just_audio has loaded the voice asset.
      await tester.tap(find.byIcon(Icons.play_circle));
      await pumpUntil(
        tester,
        () => _audioState(tester).status == AudioStatus.playing,
        description: 'voice cue playing',
      );

      await tester.tap(find.byType(VoiceMuteButton));
      await pumpUntilFound(tester, _faIcon(FontAwesomeIcons.commentSlash));
      expect(_audioState(tester).isMuted, isTrue);
      expect(_audioState(tester).status, AudioStatus.idle);
      expect(find.byTooltip(l10nOf(tester).voiceCuesOff), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_circle));
      await pumpUntilFound(tester, find.byIcon(Icons.play_circle));

      await tester.tap(find.byType(VoiceMuteButton));
      await pumpUntilFound(tester, _faIcon(FontAwesomeIcons.commentDots));
      expect(_audioState(tester).isMuted, isFalse);
      expect(find.byTooltip(l10nOf(tester).voiceCuesOn), findsOneWidget);
    });

    testWidgets('stummgeschaltet → Play spielt keine Sprachansage', (
      tester,
    ) async {
      await launchToSessionPage(tester);

      await tester.tap(find.byType(VoiceMuteButton));
      await pumpUntilFound(tester, _faIcon(FontAwesomeIcons.commentSlash));

      await tester.tap(find.byIcon(Icons.play_circle));
      await pumpUntilFound(tester, find.byIcon(Icons.pause_circle));
      await tester.pump(const Duration(seconds: 1));
      expect(_audioState(tester).status, AudioStatus.idle);

      await tester.tap(find.byIcon(Icons.pause_circle));
      await pumpUntilFound(tester, find.byIcon(Icons.play_circle));
    });
  });
}
