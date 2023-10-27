import 'package:bloc/bloc.dart';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';

@immutable
sealed class CliqueEvent {}

final class CliqueLoad extends CliqueEvent {
  final CliqueId cliqueId;

  CliqueLoad({required this.cliqueId});
}

final class CliqueIncreaseScore extends CliqueEvent {
  final CliqueId cliqueId;
  final User user;
  final int increase;

  CliqueIncreaseScore({required this.cliqueId, required this.user, required this.increase});
}

final class CliqueJoin extends CliqueEvent {
  final CliqueId cliqueId;
  final User user;

  CliqueJoin({required this.cliqueId, required this.user});
}

final class CliqueLeave extends CliqueEvent {
  final CliqueId cliqueId;
  final User user;

  CliqueLeave({required this.cliqueId, required this.user});
}

@immutable
sealed class CliqueState extends Equatable {}

final class CliqueInitial extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueLoadingInProgress extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueLoadingSuccess extends CliqueState {
  final Clique clique;
  final List<Score> allScoresSorted;

  CliqueLoadingSuccess({
    required this.clique,
    required this.allScoresSorted,
  });

  @override
  List<Object?> get props => [clique, allScoresSorted];
}

final class CliqueLoadingFailure extends CliqueState {
  final RepositoryError error;

  CliqueLoadingFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class CliqueIncreaseScoreInProgress extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueIncreaseScoreSuccess extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueIncreaseScoreFailure extends CliqueState {
  final RepositoryError error;

  CliqueIncreaseScoreFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class CliqueJoinInProgress extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueJoinSuccess extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueJoinFailure extends CliqueState {
  final RepositoryError error;

  CliqueJoinFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class CliqueLeaveInProgress extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueLeaveSuccess extends CliqueState {
  @override
  List<Object?> get props => [];
}

final class CliqueLeaveFailure extends CliqueState {
  final RepositoryError error;

  CliqueLeaveFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class CliqueBloc extends Bloc<CliqueEvent, CliqueState> {
  final CliqueRepository _cliqueRepo;

  CliqueBloc(
      {required CliqueRepository cliqueRepository})
      : _cliqueRepo = cliqueRepository,
        super(CliqueInitial()) {
    on<CliqueEvent>(
      (CliqueEvent event, Emitter<CliqueState>emit) async {
        switch (event) {
          case CliqueLoad():
            await _handleCliqueLoadEvent(event: event, emit: emit);
          case CliqueIncreaseScore():
            await _handleCliqueIncreaseScoreEvent(event: event, emit: emit);
          case CliqueJoin():
            await  _handleCliqueJoinEvent(event: event, emit: emit);
          case CliqueLeave():
            await _handleCliqueLeaveEvent(event: event, emit: emit);
        }
      },
    );
  }

  Future<void> _handleCliqueLoadEvent({required CliqueLoad event, required Emitter<CliqueState> emit}) async {
    emit(CliqueLoadingInProgress());

    Either<RepositoryError, Clique> cliqueResult = await _cliqueRepo.getClique(cliqueId: event.cliqueId);

    await cliqueResult.match(
            (l) async => emit(CliqueLoadingFailure(error: l)),
            (rClique) async {
              Either<RepositoryError, Stream<List<Score>>> scoreResult = _cliqueRepo.readScoresFromClique(cliqueId: event.cliqueId);

              await scoreResult.match(
                      (l) async => emit(CliqueLoadingFailure(error: l)),
                      (rStream) async => emit.forEach(rStream, onData: (List<Score> scores) {
                        scores.sort((a, b) => a.score > b.score ? -1 : 1);
                        return CliqueLoadingSuccess(clique: rClique, allScoresSorted: scores);
                      })
              );
            }
    );
  }

  Future<void> _handleCliqueIncreaseScoreEvent({required CliqueIncreaseScore event, required Emitter<CliqueState> emit}) async {
    emit(CliqueIncreaseScoreInProgress());

    Either<RepositoryError, Score> scoreResult = await _cliqueRepo.getScore(cliqueId: event.cliqueId, userId: event.user.id);
    await scoreResult.match(
            (l) async => emit(CliqueIncreaseScoreFailure(error: l)),
            (r) async {
              Option<RepositoryError> updateResult = await _cliqueRepo.increaseScore(cliqueId: event.cliqueId, score: r, scoreIncrease: event.increase);

              updateResult.match(
                      () => emit(CliqueIncreaseScoreSuccess()),
                      (t) =>  emit(CliqueIncreaseScoreFailure(error: t))
              );
            }
    );
  }

  Future<void> _handleCliqueJoinEvent({required CliqueJoin event, required Emitter<CliqueState> emit}) async {
    emit(CliqueJoinInProgress());

    Option<RepositoryError> result = await _cliqueRepo.addUser(cliqueId: event.cliqueId, user: event.user);

    result.match(
            () => emit(CliqueJoinSuccess()),
            (t) => emit(CliqueJoinFailure(error: t)))
    ;
  }

  Future<void> _handleCliqueLeaveEvent({required CliqueLeave event, required Emitter<CliqueState> emit}) async {
    emit(CliqueLeaveInProgress());

    Option<RepositoryError> result = await _cliqueRepo.removeUser(cliqueId: event.cliqueId, userId: event.user.id);

    result.match(
            () => emit(CliqueLeaveSuccess()),
            (t) => emit(CliqueLeaveFailure(error: t)))
    ;
  }


}
