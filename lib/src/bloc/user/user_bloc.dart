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
  List<Object?> get props => [];
}

final class UserRegisterInProgress extends UserState {
  @override
  List<Object?> get props => [];
}

final class UserRegisterSuccess extends UserState {
  final User user;

  UserRegisterSuccess({required this.user});

  @override
  List<Object?> get props => [];
}

final class UserRegisterFailure extends UserState {
  final RepositoryError error;

  UserRegisterFailure({required this.error});

  @override
  List<Object?> get props => [];
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
  List<Object?> get props => [];
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
  List<Object?> get props => [];
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
      (event, emit) async {
        switch (event) {
          case UserStarted():
            _handleUserStartedEvent(event: event, emit: emit);
          case UserRegister():
            _handleUserRegisterEvent(event: event, emit: emit);
          case UserLogin():
            _handleUserLoginEvent(event: event, emit: emit);
          case UserLogout():
            _handleUserLogoutEvent(event: event, emit: emit);
          case UserDelete():
            _handleUserDeleteEvent(event: event, emit: emit);
        }
      },
    );
  }

  void _handleUserStartedEvent({required UserStarted event, required Emitter<UserState> emit}) async {
    emit(UserLoginInProgress());
    // TODO: Attempt to login using potentially stored local token.
  }

  void _handleUserRegisterEvent({required UserRegister event, required Emitter<UserState> emit}) async {
    emit(UserRegisterInProgress());
    Either<RepositoryError, User> result = await _authRepo.registerUser(email: event.email, password: event.password, userName: event.name);

    result.match(
            (l) => emit(UserRegisterFailure(error: l)),
            (r) => emit(UserRegisterSuccess(user: r))
    );
  }

  void _handleUserLoginEvent({required UserLogin event, required Emitter<UserState> emit}) async {
    emit(UserLoginInProgress());
    Either<RepositoryError, User> result = await _authRepo.loginUser(email: event.email, password: event.password);

    result.match(
            (l) => emit(UserLoginFailure(error: l)),
            (r) => emit(UserLoginSuccess(user: r))
    );
  }

  void _handleUserLogoutEvent({required UserLogout event, required Emitter<UserState> emit}) {
    emit(UserLogoutInProgress());
    Option<RepositoryError> result = _authRepo.logoutUser();

    result.match(
            () => emit(UserLogoutSuccess()),
            (t) => emit(UserLogoutFailure(error: t))
    );
  }

  void _handleUserDeleteEvent({required UserDelete event, required Emitter<UserState> emit}) async {
    emit(UserDeleteInProgress());
    Option<RepositoryError> result = await _authRepo.deleteUser();

    result.match(
            () => emit(UserDeleteSuccess()),
            (t) => emit(UserDeleteFailure(error: t))
    );
  }
}
