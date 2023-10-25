import 'package:firedart/firedart.dart';
import 'package:firedart/auth/user_gateway.dart' as auth;
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';
import 'package:clique_king_model/clique_king_model.dart';


@immutable
class AuthenticationRepository {
  final FirebaseAuth authentication;

  bool get isUserLoggedIn => authentication.isSignedIn;

  AuthenticationRepository({required this.authentication});

  Future<Either<RepositoryError, User>> registerUser({required String email, required String password, required String userName}) async {
    final auth.User authUser;
    try {
      await authentication.signUp(email, password);
    } catch(e) {
      return Either.left(FailedToRegisterAccount(errorObject: e));
    }

    try {
      await authentication.updateProfile(displayName: userName);
    } catch(e) {
      return Either.left(FailedToUpdateAccount(errorObject: e));
    }

    try {
      authUser = await authentication.getUser();
    } catch(e) {
      return Either.left(FailedToGetAccount(errorObject: e));
    }

    return Either.right(User.fromAuthUser(authUser));
  }

  Future<Either<RepositoryError, User>> getLoggedInUser() async {
    auth.User authUser;
    try {
      authUser = await authentication.getUser();
    } catch(e) {
      return Either.left(FailedToGetAccount(errorObject: e));
    }

    return Either.right(User.fromAuthUser(authUser));
  }

  Future<Either<RepositoryError, User>> loginUser({required String email, required String password}) async {
    auth.User authUser;
    try {
      authUser = await authentication.signIn(email, password);
    } catch(e) {
      return Either.left(WrongLoginCredentials(errorObject: e));
    }

    return Either.right(User.fromAuthUser(authUser));
  }

  Future<Option<RepositoryError>> logoutUser() async {
    try {
      authentication.signOut();
    } catch(e) {
      return Option.of(FailedToLogoutAccount(errorObject: e));
    }

    return Option.none();
  }

  Future<Option<RepositoryError>> deleteUser() async {
    try {
      await authentication.deleteAccount();
    } catch(e) {
      return Option.of(FailedToDeleteAccount(errorObject: e));
    }

    return Option.none();
  }
}
