import 'package:bloc/bloc.dart';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

@immutable
sealed class UserEvent {}

final class UserStarted extends UserEvent {}

final class UserRegister extends UserEvent {
  final String email;
  final String password;
  final String name;

  UserRegister(
      {required this.email, required this.password, required this.name});
}

final class UserUpdate extends UserEvent {
  final String name;

  UserUpdate({required this.name});
}

final class UserLogin extends UserEvent {
  final String email;
  final String password;

  UserLogin({required this.email, required this.password});
}

final class UserLogout extends UserEvent {}

final class UserDelete extends UserEvent {}

// ---

@immutable
sealed class UserState extends Equatable {}

final class UserInitial extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserLoginInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserLoginSuccess extends UserState {
  final User user;

  UserLoginSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

final class UserLoginFailure extends UserState {
  final RepositoryError error;

  UserLoginFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class UserRegisterInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserRegisterSuccess extends UserState {
  final User user;

  UserRegisterSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

final class UserRegisterFailure extends UserState {
  final RepositoryError error;

  UserRegisterFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class UserUpdateInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserUpdateSuccess extends UserState {
  final User user;

  UserUpdateSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

final class UserUpdateFailure extends UserState {
  final RepositoryError error;

  UserUpdateFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class UserLogoutInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserLogoutSuccess extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserLogoutFailure extends UserState {
  final RepositoryError error;

  UserLogoutFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class UserDeleteInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserDeleteSuccess extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserDeleteFailure extends UserState {
  final RepositoryError error;

  UserDeleteFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepo; // passed in so it can be easily mocked
  final AuthenticationRepository _authRepo; // passed in so it can be easily mocked

  UserBloc(
      {required UserRepository userRepository,
      required AuthenticationRepository authenticationRepository})
      : _userRepo = userRepository,
        _authRepo = authenticationRepository,
        super(UserInitial()) {
    on<UserEvent>(
      (UserEvent event, Emitter<UserState> emit) async {
        switch (event) {
          case UserStarted():
            await _handleUserStartedEvent(event: event, emit: emit);
          case UserRegister():
            await _handleUserRegisterEvent(event: event, emit: emit);
          case UserUpdate():
            await _handleUserUpdateEvent(event: event, emit: emit);
          case UserLogin():
            await _handleUserLoginEvent(event: event, emit: emit);
          case UserLogout():
            await _handleUserLogoutEvent(event: event, emit: emit);
          case UserDelete():
            await _handleUserDeleteEvent(event: event, emit: emit);
        }
      },
    );
  }

  Future<void> _handleUserStartedEvent({required UserStarted event, required Emitter<UserState> emit}) async {
    emit(UserLoginInProgress());
    if(_authRepo.isUserLoggedIn) {
      Either<RepositoryError, User> result = await _authRepo.getLoggedInUser();
      result.match(
              (l) => emit(UserLoginFailure(error: l)),
              (r) => emit(UserLoginSuccess(user: r))
      );
    } else {
      RepositoryError notLoggedInError = AccountNotLoggedIn(errorObject: "User is not logged in");
      emit(UserLoginFailure(error: notLoggedInError));
    }
  }

  Future<void> _handleUserRegisterEvent({required UserRegister event, required Emitter<UserState> emit}) async {
    emit(UserRegisterInProgress());
    Either<RepositoryError, bool> existResult = await _userRepo.userExists(userName: event.name);

    bool error = existResult.match(
            (l) {
              emit(UserRegisterFailure(error: l));
              return true;
            },
            (r) {
              if(r) {
                RepositoryError userExistsError = UserNameAlreadyInUse(errorObject: "User name is already in use.");
                emit(UserRegisterFailure(error: userExistsError));
              }
              return r;
            }
    );

    if(error) return;

    Either<RepositoryError, User> registerResult = await _authRepo.registerUser(email: event.email, password: event.password, userName: event.name);

    await registerResult.match(
            (l) async => emit(UserRegisterFailure(error: l)),
            (r) async {
              Either<RepositoryError, User> createResult = await _userRepo.createUser(user: r);

              createResult.match(
                      (l) => emit(UserRegisterFailure(error: l)),
                      (r) => emit(UserRegisterSuccess(user: r))
              );
            }
    );
  }

  Future<void> _handleUserUpdateEvent({required UserUpdate event, required Emitter<UserState> emit}) async {
    emit(UserUpdateInProgress());
    Either<RepositoryError, bool> existResult = await _userRepo.userExists(userName: event.name);

    bool error = existResult.match(
            (l) {
              emit(UserUpdateFailure(error: l));
              return true;
        },
            (r) {
          if(r) {
            RepositoryError userExistsError = UserNameAlreadyInUse(errorObject: "User name is already in use.");
            emit(UserUpdateFailure(error: userExistsError));
          }
          return r;
        }
    );

    if(error) return;

    Either<RepositoryError, User> accountResult = await _authRepo.updateUser(userName: event.name);

    await accountResult.match(
            (l) async => emit(UserUpdateFailure(error: l)),
            (r) async {
              Either<RepositoryError, User> userResult = await _userRepo.updateUser(user: r);

              userResult.match(
                      (l) => emit(UserUpdateFailure(error: l)),
                      (r) => emit(UserUpdateSuccess(user: r))
              );
            }
    );
  }

  Future<void> _handleUserLoginEvent({required UserLogin event, required Emitter<UserState> emit}) async {
    emit(UserLoginInProgress());
    Either<RepositoryError, User> result = await _authRepo.loginUser(email: event.email, password: event.password);

    result.match(
            (l) => emit(UserLoginFailure(error: l)),
            (r) => emit(UserLoginSuccess(user: r))
    );
  }

  Future<void> _handleUserLogoutEvent({required UserLogout event, required Emitter<UserState> emit}) async {
    emit(UserLogoutInProgress());
    Option<RepositoryError> result = await _authRepo.logoutUser();

    result.match(
            () => emit(UserLogoutSuccess()),
            (t) => emit(UserLogoutFailure(error: t))
    );
  }

  Future<void> _handleUserDeleteEvent({required UserDelete event, required Emitter<UserState> emit}) async {
    emit(UserDeleteInProgress());
    Either<RepositoryError, User> loggedInResult = await _authRepo.getLoggedInUser();

    await loggedInResult.match(
            (l) async => emit(UserDeleteFailure(error: l)),
            (r) async {
              Option<RepositoryError> deleteUserResult = await _userRepo.deleteUser(id: r.id);

              await deleteUserResult.match(
                      () async {
                        Option<RepositoryError> deleteAccountResult = await _authRepo.deleteUser();

                        deleteAccountResult.match(
                                () => emit(UserDeleteSuccess()),
                                (t) => emit(UserDeleteFailure(error: t))
                        );
                      },
                      (t) async => emit(UserDeleteFailure(error: t))
              );
            }
    );
  }
}
