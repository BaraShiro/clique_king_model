import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';

/// base class for Cliques Events.
@immutable
sealed class CliquesEvent {}

/// Load all cliques.
final class CliquesLoad extends CliquesEvent {}

/// Add a new clique.
final class AddClique extends CliquesEvent {
  final String name;

  AddClique({required this.name});
}

/// Remove a clique.
final class RemoveClique extends CliquesEvent {
  final CliqueId cliqueId;

  RemoveClique({required this.cliqueId});
}

/// Base class for Cliques States.
@immutable
sealed class CliquesState extends Equatable {}

/// Initial Cliques State.
final class CliquesInitial extends CliquesState {
  @override
  List<Object?> get props => [];
}

/// Loading of all cliques has started.
final class CliquesLoadingInProgress extends CliquesState {
  @override
  List<Object?> get props => [];
}

/// Loading of all cliques was successful.
final class CliquesLoadingSuccess extends CliquesState {
  final List<Clique> cliques;

  CliquesLoadingSuccess({required this.cliques});

  @override
  List<Object?> get props => [cliques];
}

/// Loading of all cliques has failed.
final class CliquesLoadingFailure extends CliquesState {
  final RepositoryError error;

  CliquesLoadingFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Add a new clique has started.
final class AddCliqueInProgress extends CliquesState {
  @override
  List<Object?> get props => [];
}

/// Add a new clique was successful.
final class AddCliqueSuccess extends CliquesState {
  final Clique clique;

  AddCliqueSuccess({required this.clique});

  @override
  List<Object?> get props => [];
}

/// Add a new clique has failed.
final class AddCliqueFailure extends CliquesState {
  final RepositoryError error;

  AddCliqueFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Remove a clique has started.
final class RemoveCliqueInProgress extends CliquesState {
  @override
  List<Object?> get props => [];
}

/// Remove a clique was successful.
final class RemoveCliqueSuccess extends CliquesState {
  @override
  List<Object?> get props => [];
}

/// Remove a clique has failed.
final class RemoveCliqueFailure extends CliquesState {
  final RepositoryError error;

  RemoveCliqueFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// The Cliques Bloc class.
final class CliquesBloc extends Bloc<CliquesEvent, CliquesState> {
  final CliqueRepository _cliqueRepo;
  final AuthenticationRepository _authRepo;

  CliquesBloc({required CliqueRepository cliqueRepository,
              required AuthenticationRepository authenticationRepository})
      : _cliqueRepo = cliqueRepository,
        _authRepo = authenticationRepository,
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

  /// Handles Cliques Load Event.
  ///
  /// Emits [CliquesLoadingInProgress], and then emits either:
  /// * [CliquesLoadingFailure] if unable to read cliques.
  /// * [CliquesLoadingSuccess] if cliques were read successfully.
  Future<void> _handleCliquesLoadEvent({required CliquesLoad event, required Emitter<CliquesState> emit}) async {
    emit(CliquesLoadingInProgress());

    Either<RepositoryError, Stream<List<Clique>>> result = _cliqueRepo.readAllCliques();

    await result.match(
            (l) async => emit(CliquesLoadingFailure(error: l)),
            (r) async => emit.forEach(r, onData: (List<Clique> cliques) => CliquesLoadingSuccess(cliques: cliques))
    );
  }

  /// Handles Add Clique Event.
  ///
  /// Emits [AddCliqueInProgress], and then emits either:
  /// * [AddCliqueFailure] if unable to read logged in user or write new clique.
  /// * [AddCliqueSuccess] if new cliques were successfully written.
  Future<void> _handleAddCliqueEvent({required AddClique event, required Emitter<CliquesState> emit}) async {
    emit(AddCliqueInProgress());
    // TODO: Check for name collision
    // TODO: Sanitize name

    Either<RepositoryError, User> userResult = await _authRepo.getLoggedInUser();

    await userResult.match(
            (l) async => emit(AddCliqueFailure(error: l)),
            (rUser) async {
              Either<RepositoryError, Clique> result = await _cliqueRepo.createClique(name: event.name, creatorId: rUser.id);

              result.match(
                      (l) => emit(AddCliqueFailure(error: l)),
                      (rClique) => emit(AddCliqueSuccess(clique: rClique))
              );
            }
    );

  }

  /// Handles Remove Clique Event
  ///
  /// Emits [RemoveCliqueInProgress], and then emits either:
  /// * [RemoveCliqueFailure] if unable to read clique or logged in user,
  /// unable to delete clique, or if user lacks permission to delete clique.
  /// * [RemoveCliqueSuccess] if clique was deleted successfully.
  Future<void> _handleRemoveCliqueEvent({required RemoveClique event, required Emitter<CliquesState> emit}) async {
    emit(RemoveCliqueInProgress());

    Either<RepositoryError, User> userResult = await _authRepo.getLoggedInUser();

    bool userHasPermission = await userResult.match(
            (l) async {
              emit(RemoveCliqueFailure(error: l));
              return false;
            },
            (rUser) async {
              Either<RepositoryError, Clique> cliqueResult = await _cliqueRepo.getClique(cliqueId: event.cliqueId);

              return cliqueResult.match(
                      (l) {
                        emit(RemoveCliqueFailure(error: l));
                        return false;
                      },
                      (rClique) {
                        return rClique.creatorId == rUser.id;
                      }
              );
            }
    );

    if(userHasPermission) {
      Option<RepositoryError> result = await _cliqueRepo.deleteClique(cliqueId: event.cliqueId);

      result.match(
              () => emit(RemoveCliqueSuccess()),
              (t) => emit(RemoveCliqueFailure(error: t))
      );
    } else {
      RepositoryError error = UserPermissionViolation(errorObject: "Only the creator of a clique can delete it.");
      emit(RemoveCliqueFailure(error: error));
    }

  }

}
