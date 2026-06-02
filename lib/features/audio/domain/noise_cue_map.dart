import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';

abstract final class NoiseCueMap {
  static const String _basePath = 'assets/noises';

  static const Map<PhaseType, String> _paths = {
    PhaseType.inhale: '$_basePath/inhale.mp3',
    PhaseType.extendedInhale: '$_basePath/deep_inhale.mp3',
    PhaseType.holdIn: '$_basePath/hold.mp3',
    PhaseType.exhale: '$_basePath/exhale.mp3',
    PhaseType.extendedExhale: '$_basePath/deep_exhale.mp3',
    PhaseType.holdOut: '$_basePath/hold.mp3',
  };

  static String? assetPath(PhaseType phase) => _paths[phase];
}
