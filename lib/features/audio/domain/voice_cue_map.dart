import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';

abstract final class VoiceCueMap {
  static const String _basePath = 'assets/voices';

  static const Map<PhaseType, String> _paths = {
    PhaseType.inhale: '$_basePath/breath_in.mp3',
    // TODO(audio): replace with dedicated breath_in_deeply.mp3 when recorded.
    PhaseType.extendedInhale: '$_basePath/breath_in.mp3',
    PhaseType.holdIn: '$_basePath/hold.mp3',
    PhaseType.exhale: '$_basePath/breath_out.mp3',
    PhaseType.extendedExhale: '$_basePath/breath_out_deeply.mp3',
    PhaseType.holdOut: '$_basePath/hold.mp3',
  };

  static String? assetPath(PhaseType phase) => _paths[phase];
}
