import 'dart:convert';

import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter/services.dart';

class ProgramsRepository {
  const ProgramsRepository._();

  static Future<List<SessionProgram>> load() async {
    final raw = await rootBundle.loadString('assets/breathing_programs.json');
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final list = doc['programs'] as List<dynamic>;
    final programs = <SessionProgram>[];
    for (final entry in list.cast<Map<String, dynamic>>()) {
      try {
        programs.add(SessionProgram.fromJson(entry));
      } catch (_) {
        // Skip any program that fails to parse (e.g. unknown progression kind)
        // so a single malformed entry does not prevent the rest from loading.
      }
    }
    return programs;
  }
}
