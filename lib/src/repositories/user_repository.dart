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
      document = await store
          .collection(userCollection)
          .document(user.id)
          .create(user.toMap());
    } catch (e) {
      return Either.left(FailedToCreateUser(errorObject: e));
    }
    return Either.right(User.fromMap(document.map));
  }

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
