import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';

@immutable
sealed class CliquesEvent {}

final class CliquesLoad extends CliquesEvent {}

final class AddClique extends CliquesEvent {
  final String name;

  AddClique({required this.name});
}

final class RemoveClique extends CliquesEvent {
  final CliqueId cliqueId;

  RemoveClique({required this.cliqueId});
}

@immutable
sealed class CliquesState extends Equatable {}

final class CliquesInitial extends CliquesState {
  @override
  List<Object?> get props => [];
}

final class CliquesLoadingInProgress extends CliquesState {
  @override
  List<Object?> get props => [];
}

final class CliquesLoadingSuccess extends CliquesState {
  final List<Clique> cliques;

  CliquesLoadingSuccess({required this.cliques});

  @override
  List<Object?> get props => [cliques];
}

final class CliquesLoadingFailure extends CliquesState {
  final RepositoryError error;

  CliquesLoadingFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
final class AddCliqueInProgress extends CliquesState {
  @override
  List<Object?> get props => [];
}
final class AddCliqueSuccess extends CliquesState {
  final Clique clique;

  AddCliqueSuccess({required this.clique});

  @override
  List<Object?> get props => [];
}

final class AddCliqueFailure extends CliquesState {
  final RepositoryError error;

  AddCliqueFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class RemoveCliqueInProgress extends CliquesState {
  @override
  List<Object?> get props => [];
}

final class RemoveCliqueSuccess extends CliquesState {
  @override
  List<Object?> get props => [];
}

final class RemoveCliqueFailure extends CliquesState {
  final RepositoryError error;

  RemoveCliqueFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class CliquesBloc extends Bloc<CliquesEvent, CliquesState> {
  final CliqueRepository _cliqueRepo;

  CliquesBloc({required CliqueRepository cliqueRepository})
      : _cliqueRepo = cliqueRepository,
        super(CliquesInitial()) {
    on<CliquesEvent>(
      (CliquesEvent event, Emitter<CliquesState> emit) async {
        switch (event) {
          case CliquesLoad():
            await _handleCliquesLoadEvent(event: event, emit: emit);
          case AddClique():
            await _handleAddCliqueEvent(event: event, emit: emit);
          case RemoveClique():
            await _handleRemoveCliqueEvent(event: event, emit: emit);
        }
      },
    );
  }

  Future<void> _handleCliquesLoadEvent({required CliquesLoad event, required Emitter<CliquesState> emit}) async {
    emit(CliquesLoadingInProgress());

    Either<RepositoryError, Stream<List<Clique>>> result = _cliqueRepo.readAllCliques();

    await result.match(
            (l) async => emit(CliquesLoadingFailure(error: l)),
            (r) async => emit.forEach(r, onData: (List<Clique> cliques) => CliquesLoadingSuccess(cliques: cliques))
    );
  }

  Future<void> _handleAddCliqueEvent({required AddClique event, required Emitter<CliquesState> emit}) async {
    emit(AddCliqueInProgress());

    Either<RepositoryError, Clique> result = await _cliqueRepo.createClique(name: event.name);

    result.match(
            (l) => emit(AddCliqueFailure(error: l)),
            (r) => emit(AddCliqueSuccess(clique: r))
    );

  }

  Future<void> _handleRemoveCliqueEvent({required RemoveClique event, required Emitter<CliquesState> emit}) async {
    emit(RemoveCliqueInProgress());

    Option<RepositoryError> result = await _cliqueRepo.deleteClique(cliqueId: event.cliqueId);

    result.match(
            () => emit(RemoveCliqueSuccess()),
            (t) => emit(RemoveCliqueFailure(error: t))
    );
  }

}
