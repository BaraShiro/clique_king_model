import 'package:meta/meta.dart';

@immutable
sealed class RepositoryError {
  final Object errorObject;

  RepositoryError({required this.errorObject});
}

final class FailedToGetAccount extends RepositoryError {
  FailedToGetAccount({required super.errorObject});
}

final class FailedToRegisterAccount extends RepositoryError {
  FailedToRegisterAccount({required super.errorObject});
}

final class FailedToUpdateUser extends RepositoryError {
  FailedToUpdateUser({required super.errorObject});
}

final class FailedToUpdateAccount extends RepositoryError {
  FailedToUpdateAccount({required super.errorObject});
}

final class AccountNotLoggedIn extends RepositoryError {
  AccountNotLoggedIn({required super.errorObject});
}

final class UserNameAlreadyInUse extends RepositoryError {
  UserNameAlreadyInUse({required super.errorObject});
}

final class InvalidPassword extends RepositoryError {
  InvalidPassword({required super.errorObject});
}

final class InvalidEmail extends RepositoryError {
  InvalidEmail({required super.errorObject});
}

final class InvalidUserName extends RepositoryError {
  InvalidUserName({required super.errorObject});
}

final class WrongLoginCredentials extends RepositoryError {
  WrongLoginCredentials({required super.errorObject});
}

final class FailedToLogoutAccount extends RepositoryError {
  FailedToLogoutAccount({required super.errorObject});
}

final class FailedToDeleteAccount extends RepositoryError {
  FailedToDeleteAccount({required super.errorObject});
}

final class FailedToCreateUser extends RepositoryError {
  FailedToCreateUser({required super.errorObject});
}

final class FailedToReadUser extends RepositoryError {
  FailedToReadUser({required super.errorObject});
}

final class FailedToDeleteUser extends RepositoryError {
  FailedToDeleteUser({required super.errorObject});
}

final class FailedToCreateClique extends RepositoryError {
  FailedToCreateClique({required super.errorObject});
}

final class FailedToStreamCliques extends RepositoryError {
  FailedToStreamCliques({required super.errorObject});
}

final class FailedToStreamScores extends RepositoryError {
  FailedToStreamScores({required super.errorObject});
}

final class FailedToAddUserToClique extends RepositoryError {
  FailedToAddUserToClique({required super.errorObject});
}

final class FailedToRemoveUserFromClique extends RepositoryError {
  FailedToRemoveUserFromClique({required super.errorObject});
}

final class FailedToDeleteClique extends RepositoryError {
  FailedToDeleteClique({required super.errorObject});
}

final class FailedToReadClique extends RepositoryError {
  FailedToReadClique({required super.errorObject});
}

final class FailedToIncreaseScore extends RepositoryError {
  FailedToIncreaseScore({required super.errorObject});
}

final class FailedToReadScore extends RepositoryError {
  FailedToReadScore({required super.errorObject});
}

final class FailedToLoadCliques extends RepositoryError {
  FailedToLoadCliques({required super.errorObject});
}