import 'dart:convert';

import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter/services.dart';

class ProgramsRepository {
  const ProgramsRepository._();

  static Future<List<SessionProgram>> load() async {
    final raw = await rootBundle.loadString('assets/breathing_programs.json');
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final list = doc['programs'] as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(SessionProgram.fromJson)
        .toList();
  }
}
