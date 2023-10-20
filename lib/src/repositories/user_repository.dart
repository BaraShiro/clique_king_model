import 'package:firedart/firedart.dart';
import 'package:meta/meta.dart';
import 'package:clique_king_model/src/models/user.dart';

typedef UserId = String;

@immutable
class UserRepository {
  final Firestore store; // pass it in so it can be mocked.

  UserRepository({required this.store});

  void createUser({required User user}) async {
    // TODO: error handling
    await store.collection("users").document(user.id).create(user.toMap());
  }

  Future<User> readUser({ required UserId id}) async {
    // TODO: error handling
    Document document = await store.collection("users").document(id).get();
    return User.fromMap(document.map);
  }
  void updateUser({required User user, required String newName}) async {
    // TODO: error handling
    User updatedUser = user.updateName(newName);
    await store.collection("users").document(user.id).update(updatedUser.toMap());
  }

  void deleteUSer({required UserId id}) async {
    // TODO: error handling
    await store.collection("users").document(id).delete();
  }

}
