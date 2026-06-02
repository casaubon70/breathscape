import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/features/disclaimer/bloc/disclaimer_bloc.dart';
import 'package:breathscape/features/disclaimer/domain/disclaimer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDisclaimerRepository extends Mock implements DisclaimerRepository {}

void main() {
  late DisclaimerRepository repository;

  setUp(() {
    repository = _MockDisclaimerRepository();
  });

  group('DisclaimerBloc', () {
    group('DisclaimerCheckRequested', () {
      blocTest<DisclaimerBloc, DisclaimerState>(
        'emits [loading, notAccepted] when disclaimer not yet accepted',
        build: () {
          when(() => repository.hasAccepted()).thenAnswer((_) async => false);
          return DisclaimerBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const DisclaimerCheckRequested()),
        expect: () => [
          const DisclaimerState(status: DisclaimerStatus.loading),
          const DisclaimerState(status: DisclaimerStatus.notAccepted),
        ],
      );

      blocTest<DisclaimerBloc, DisclaimerState>(
        'emits [loading, accepted] when disclaimer already accepted',
        build: () {
          when(() => repository.hasAccepted()).thenAnswer((_) async => true);
          return DisclaimerBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const DisclaimerCheckRequested()),
        expect: () => [
          const DisclaimerState(status: DisclaimerStatus.loading),
          const DisclaimerState(status: DisclaimerStatus.accepted),
        ],
      );
    });

    group('DisclaimerAccepted', () {
      blocTest<DisclaimerBloc, DisclaimerState>(
        'emits [accepted] and persists acceptance',
        build: () {
          when(() => repository.accept()).thenAnswer((_) async {});
          return DisclaimerBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const DisclaimerAccepted()),
        expect: () => [
          const DisclaimerState(status: DisclaimerStatus.accepted),
        ],
        verify: (_) => verify(() => repository.accept()).called(1),
      );
    });
  });
}
