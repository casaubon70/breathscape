import 'package:breathscape/features/audio/domain/voice_cue_map.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceCueMap', () {
    test('inhale maps to breath_in.mp3', () {
      expect(
        VoiceCueMap.assetPath(PhaseType.inhale),
        'assets/voices/breath_in.mp3',
      );
    });

    test('holdIn maps to hold.mp3', () {
      expect(VoiceCueMap.assetPath(PhaseType.holdIn), 'assets/voices/hold.mp3');
    });

    test('exhale maps to breath_out.mp3', () {
      expect(
        VoiceCueMap.assetPath(PhaseType.exhale),
        'assets/voices/breath_out.mp3',
      );
    });

    test('extendedExhale maps to breath_out_deeply.mp3', () {
      expect(
        VoiceCueMap.assetPath(PhaseType.extendedExhale),
        'assets/voices/breath_out_deeply.mp3',
      );
    });

    test('holdOut maps to hold.mp3', () {
      expect(
        VoiceCueMap.assetPath(PhaseType.holdOut),
        'assets/voices/hold.mp3',
      );
    });

    test('all PhaseType values have a mapping', () {
      for (final phase in PhaseType.values) {
        expect(
          VoiceCueMap.assetPath(phase),
          isNotNull,
          reason: '$phase has no mapping in VoiceCueMap',
        );
      }
    });
  });
}
