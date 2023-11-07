import 'package:firedart/firedart.dart';
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';
import 'package:clique_king_model/clique_king_model.dart';

/// A repository for handling and storage of [User]s.
@immutable
class UserRepository {
  final Firestore store;

  /// Public constructor.
  UserRepository({required this.store});

  /// Stores a [User] in the repository.
  ///
  /// Returns either the [User], or a [FailedToCreateUser] error if it fails.
  Future<Either<RepositoryError, User>> createUser({required User user}) async {
    Document document;
    try {
      document = await store
          .collection(userCollection)
          .document(user.id)
          .create(user.toMap());
    } catch (e) {
      return Either.left(FailedToCreateUser(errorObject: e));
    }
    return Either.right(User.fromMap(document.map));
  }

  /// Retrieves a [User] with the user id [id] from the repository.
  ///
  /// Returns either the specified [User],
  /// or a [FailedToReadUser] error if it fails.
  Future<Either<RepositoryError, User>> readUser({required UserId id}) async {
    Document document;
    try {
      document = await store
          .collection(userCollection)
          .document(id).get();
    } catch (e) {
      return Either.left(FailedToReadUser(errorObject: e));
    }
    return Either.right(User.fromMap(document.map));
  }

  /// Checks if a [User] with the name [userName] exists in the repository.
  ///
  /// Returns either a [bool] indicating whether the user exists,
  /// or one of two errors:
  /// * [InvalidUserName] if the supplied user name is empty or just whitespace.
  /// * [FailedToQueryUsers] if the repository query fails.
  Future<Either<RepositoryError, bool>> userExists({required String userName}) async {
    userName = sanitizeUserName(userName);
    if(userName.isEmpty) return Either.left(InvalidUserName(errorObject: "Invalid user name, can not be empty or only whitespace."));

    List<Document> users;
    try {
      QueryReference query = store.collection(userCollection).where("name", isEqualTo: userName);
      users = await query.get();
    } catch(e) {
      return Either.left(FailedToQueryUsers(errorObject: e));
    }

    return Either.right(users.isNotEmpty);
  }

  /// Updates a [User] in the repository.
  ///
  /// Returns either the [User], or one of two errors:
  /// * [FailedToUpdateUser] if it fails to update the user in the repository.
  /// * [FailedToReadUser] if it fails to read back the user from the repository.
  Future<Either<RepositoryError, User>> updateUser({required User user}) async {
    Document document;
    try {
      await store
          .collection(userCollection)
          .document(user.id)
          .update(user.toMap());
    } catch (e) {
      return Either.left(FailedToUpdateUser(errorObject: e));
    }
    try {
      document = await store.collection(userCollection).document(user.id).get();
    } catch (e) {
      return Either.left(FailedToReadUser(errorObject: e));
    }

    return Either.right(User.fromMap(document.map));
  }

  /// Deletes a [User] from the repository.
  ///
  /// Returns a [FailedToDeleteUser] error if it fails, otherwise nothing.
  Future<Option<RepositoryError>> deleteUser({required UserId id}) async {
    try {
      await store
          .collection(userCollection)
          .document(id)
          .delete();
    } catch (e) {
      return Option.of(FailedToDeleteUser(errorObject: e));
    }
    return Option.none();
  }

}
