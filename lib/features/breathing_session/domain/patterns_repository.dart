import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class PatternsRepository {
  const PatternsRepository._();

  static Future<List<BreathingPattern>> load() async {
    final raw = await rootBundle.loadString('assets/breathing_patterns.yaml');
    final doc = loadYaml(raw) as YamlMap;
    final list = doc['patterns'] as YamlList;
    return list
        .cast<Map<dynamic, dynamic>>()
        .map(BreathingPattern.fromMap)
        .toList();
  }
}
