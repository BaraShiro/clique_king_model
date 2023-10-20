import 'package:firedart/firedart.dart';
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';
import 'package:clique_king_model/clique_king_model.dart';

@immutable
class UserRepository {
  final Firestore store;

  UserRepository({required this.store});

  Future<Either<RepositoryError, User>> createUser({required User user}) async {
    Document document;
    try {
      document = await store.collection("users").document(user.id).create(user.toMap());
    } catch (e) {
      return Either.left(RepositoryError(errorObject: e));
    }
    return Either.right(User.fromMap(document.map));
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

  Future<Either<RepositoryError, User>> updateUser({required User user, required String newName}) async {
    User updatedUser = user.updateName(newName);
    Document document;
    try {
      await store.collection("users").document(user.id).update(updatedUser.toMap());
      document = await store.collection("users").document(user.id).get();
    } catch (e) {
      return Either.left(RepositoryError(errorObject: e));
    }
    return Either.right(User.fromMap(document.map));
  }

  Future<Option<RepositoryError>> deleteUSer({required UserId id}) async {
    try {
      await store.collection("users").document(id).delete();
    } catch (e) {
      return Option.of(RepositoryError(errorObject: e));
    }
    return Option.none();
  }

}
