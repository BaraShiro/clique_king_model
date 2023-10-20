import 'package:firedart/firedart.dart';
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';
import '/src/models/user.dart';
import '/src/repositories/repository_error.dart';

typedef UserId = String;

@immutable
class UserRepository {
  final Firestore store;

  UserRepository({required this.store});

  Future<Option<RepositoryError>> createUser({required User user}) async {
    try {
      await store.collection("users").document(user.id).create(user.toMap());
    } catch (e) {
      return Option<RepositoryError>.of(RepositoryError(errorObject: e));
    }
    return Option<RepositoryError>.none();
  }

  Future<Either<RepositoryError, User>> readUser({ required UserId id}) async {
    Document document;
    try {
      document = await store.collection("users").document(id).get();
    } catch (e) {
      return Either.left(RepositoryError(errorObject: e));
    }
    return Either.right(User.fromMap(document.map));
  }
  Future<Option<RepositoryError>> updateUser({required User user, required String newName}) async {
    User updatedUser = user.updateName(newName);
    try {
      await store.collection("users").document(user.id).update(updatedUser.toMap());
    } catch (e) {
      return Option<RepositoryError>.of(RepositoryError(errorObject: e));
    }
    return Option<RepositoryError>.none();
  }

  Future<Option<RepositoryError>> deleteUSer({required UserId id}) async {
    try {
      await store.collection("users").document(id).delete();
    } catch (e) {
      return Option<RepositoryError>.of(RepositoryError(errorObject: e));
    }
    return Option<RepositoryError>.none();
  }

}
