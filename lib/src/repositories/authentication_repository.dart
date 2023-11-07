import 'package:firedart/firedart.dart';
import 'package:firedart/auth/user_gateway.dart' as auth;
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:string_validator/string_validator.dart';

/// A repository for handling, authentication, and storage of local [User]s.
@immutable
class AuthenticationRepository {
  final FirebaseAuth authentication;

  /// Whether a user is currently logged in.
  bool get isUserLoggedIn => authentication.isSignedIn;

  /// Public constructor.
  AuthenticationRepository({required this.authentication});

  /// Registers a new user.
  ///
  /// Must supply a correctly formatted email address,
  /// a password at least 8 characters long,
  /// and a user name that is not empty or just whitespace.
  ///
  /// Returns either the newly registered [User], or any of the following errors:
  /// * [InvalidEmail] if the email is not properly formatted.
  /// * [InvalidPassword] if the password is shorter than 8 characters.
  /// * [InvalidUserName] if the username is empty or just whitespace.
  /// * [FailedToRegisterAccount] if the auth server fails to register the user.
  /// * [FailedToUpdateAccount] if the auth server fails to update the users name.
  /// * [FailedToGetAccount] if the auth server fails to retrieve the user.
  Future<Either<RepositoryError, User>> registerUser({required String email, required String password, required String userName}) async {
    if(isEmail(email)) {
      email = normalizeEmail(email);
    } else {
      return Either.left(InvalidEmail(errorObject: "Invalid email address."));
    }

    if(!isLength(password, minimumPasswordLength)) {
      return Either.left(InvalidPassword(errorObject: "Password must be at least 8 characters long."));
    }

    userName = sanitizeUserName(userName);
    if(userName.isEmpty) return Either.left(InvalidUserName(errorObject: "Invalid user name, can not be empty or only whitespace."));

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

  /// Updates the name of a user.
  ///
  /// Supplied name must not be empty or just whitespace.
  ///
  /// Returns either an updated [User], a any of the following errors:
  /// * [InvalidUserName] if the username is empty or just whitespace.
  /// * [FailedToUpdateAccount] if the auth server fails to update the users name.
  /// * [FailedToGetAccount] if the auth server fails to retrieve the user.
  // TODO: tests
  Future<Either<RepositoryError, User>> updateUser({required String userName}) async {
    userName = sanitizeUserName(userName);
    if(userName.isEmpty) return Either.left(InvalidUserName(errorObject: "Invalid user name, can not be empty or only whitespace."));

    try {
    await authentication.updateProfile(displayName: userName);
    } catch(e) {
    return Either.left(FailedToUpdateAccount(errorObject: e));
    }

    final auth.User authUser;

    try {
      authUser = await authentication.getUser();
    } catch(e) {
      return Either.left(FailedToGetAccount(errorObject: e));
    }

    return Either.right(User.fromAuthUser(authUser));
  }

  /// Returns either the currently logged in [User], if any,
  /// or a [FailedToGetAccount] error otherwise.
  Future<Either<RepositoryError, User>> getLoggedInUser() async {
    auth.User authUser;
    try {
      authUser = await authentication.getUser();
    } catch(e) {
      return Either.left(FailedToGetAccount(errorObject: e));
    }

    return Either.right(User.fromAuthUser(authUser));
  }

  /// Logs in a user associated with [email] if the correct [password] is supplied.
  ///
  /// Returns either the logged in [User] if successful,
  /// or a [WrongLoginCredentials] error otherwise.
  Future<Either<RepositoryError, User>> loginUser({required String email, required String password}) async {
    email = normalizeEmail(email);

    auth.User authUser;
    try {
      authUser = await authentication.signIn(email, password);
    } catch(e) {
      return Either.left(WrongLoginCredentials(errorObject: e));
    }

    return Either.right(User.fromAuthUser(authUser));
  }

  /// Logs out the currently logged in user.
  ///
  /// Returns a [FailedToLogoutAccount] error if it fails, otherwise nothing.
  Future<Option<RepositoryError>> logoutUser() async {
    try {
      authentication.signOut();
    } catch(e) {
      return Option.of(FailedToLogoutAccount(errorObject: e));
    }

    return Option.none();
  }

  /// Logs out and _permanently_ deletes the currently logged in user account.
  ///
  /// Returns a [FailedToDeleteAccount] error if it fails, otherwise nothing.
  Future<Option<RepositoryError>> deleteUser() async {
    try {
      await authentication.deleteAccount();
    } catch(e) {
      return Option.of(FailedToDeleteAccount(errorObject: e));
    }

    return Option.none();
  }
}
