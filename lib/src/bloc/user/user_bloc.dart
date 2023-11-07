import 'package:bloc/bloc.dart';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

/// Base class for User Events
@immutable
sealed class UserEvent {}

/// App is starting.
final class UserStarted extends UserEvent {}

/// Register a user.
final class UserRegister extends UserEvent {
  final String email;
  final String password;
  final String name;

  UserRegister(
      {required this.email, required this.password, required this.name});
}

/// Update a user.
final class UserUpdate extends UserEvent {
  final String name;

  UserUpdate({required this.name});
}

/// Log in a user.
final class UserLogin extends UserEvent {
  final String email;
  final String password;

  UserLogin({required this.email, required this.password});
}

/// Log out a user.
final class UserLogout extends UserEvent {}

/// Delete a user.
final class UserDelete extends UserEvent {}

/// Base class for User State.
@immutable
sealed class UserState extends Equatable {}

/// Initial User State.
final class UserInitial extends UserState {
  @override
  List<Object?> get props => [];
}

/// Login user has started.
final class UserLoginInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

/// Login user was successfull.
final class UserLoginSuccess extends UserState {
  final User user;

  UserLoginSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Login user has failed.
final class UserLoginFailure extends UserState {
  final RepositoryError error;

  UserLoginFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Register user has started.
final class UserRegisterInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

/// Register user was successful.
final class UserRegisterSuccess extends UserState {
  final User user;

  UserRegisterSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Register user has failed.
final class UserRegisterFailure extends UserState {
  final RepositoryError error;

  UserRegisterFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Update user has started.
final class UserUpdateInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

/// Update user was successful.
final class UserUpdateSuccess extends UserState {
  final User user;

  UserUpdateSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Update user has failed.
final class UserUpdateFailure extends UserState {
  final RepositoryError error;

  UserUpdateFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Logout user has started.
final class UserLogoutInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

/// Logout user was successful.
final class UserLogoutSuccess extends UserState {
  @override
  List<Object?> get props => [];
}

/// Logout user has failed.
final class UserLogoutFailure extends UserState {
  final RepositoryError error;

  UserLogoutFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Delete user has started.
final class UserDeleteInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

/// Delete user was successful.
final class UserDeleteSuccess extends UserState {
  @override
  List<Object?> get props => [];
}

/// Delete user has failed.
final class UserDeleteFailure extends UserState {
  final RepositoryError error;

  UserDeleteFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// User Bloc class.
final class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepo;
  final AuthenticationRepository _authRepo;

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

  /// Handles User Started Event
  ///
  /// Emits [UserLoginInProgress], and then emits either:
  /// * [UserLoginFailure] if no user is logged in.
  /// * [UserLoginSuccess] if a user is logged in.
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

  /// Handles User Register Event
  ///
  /// Emits [UserRegisterInProgress], and then emits either:
  /// * [UserRegisterFailure] if user already exists or unable to check if user
  /// already exists, unable to register user, or unable to write user.
  /// * [UserRegisterSuccess] if user was successfully registered and written.
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

  /// Handles User Update Event
  ///
  /// Emits [UserUpdateInProgress], and then emits either:
  /// * [UserUpdateFailure] if user already exists or unable to check if user
  // already exists, unable to update user account, or unable to update user.
  /// * [UserUpdateSuccess] if successfully updated user and user account.
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

  /// Handles User Login Event
  ///
  /// Emits [UserLoginInProgress], and then emits either:
  /// * [UserLoginFailure] if unable to log in.
  /// * [UserLoginSuccess] if successfully logged in.
  Future<void> _handleUserLoginEvent({required UserLogin event, required Emitter<UserState> emit}) async {
    emit(UserLoginInProgress());
    Either<RepositoryError, User> result = await _authRepo.loginUser(email: event.email, password: event.password);

    result.match(
            (l) => emit(UserLoginFailure(error: l)),
            (r) => emit(UserLoginSuccess(user: r))
    );
  }

  /// Handles User Logout Event
  ///
  /// Emits [UserLogoutInProgress], and then emits either:
  /// * [UserLogoutFailure] if unable to log out.
  /// * [UserLogoutSuccess] if successfully logged out.
  Future<void> _handleUserLogoutEvent({required UserLogout event, required Emitter<UserState> emit}) async {
    emit(UserLogoutInProgress());
    Option<RepositoryError> result = await _authRepo.logoutUser();

    result.match(
            () => emit(UserLogoutSuccess()),
            (t) => emit(UserLogoutFailure(error: t))
    );
  }

  /// Handles User Delete Event
  ///
  /// Emits [UserDeleteInProgress], and then emits either:
  /// * [UserDeleteFailure] if unable to read logged in user, or unable to
  /// delete user account or user.
  /// * [UserDeleteSuccess] if successfully deleted user account and user.
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
