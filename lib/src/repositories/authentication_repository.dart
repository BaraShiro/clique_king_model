import 'package:firedart/firedart.dart';
import 'package:firedart/auth/user_gateway.dart' as user_gateway;
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';
import '../models/user.dart';

@immutable
class AuthenticationRepository {
  final FirebaseAuth auth; // pass it in so it can be mocked.

  AuthenticationRepository({required this.auth});

  Future<Option<User>> registerUser({required String email, required String password, required String userName}) async {
    final user_gateway.User user;
    try {
      await auth.signUp(email, password);
    } catch(e) {
      return Option<User>.none();
    }

    try {
      await auth.updateProfile(displayName: userName);
    } catch(e) {
      return Option<User>.none();
    }

    try {
      user = await auth.getUser();
    } catch(e) {
      return Option<User>.none();
    }

    return Option<User>.of(
        User(
          id: user.id,
          name: user.displayName != null ? user.displayName! : "",
          email: user.email != null ? user.email! : "",
        )
    );
  }

  Future<Option<User>> loginUser({required String email, required String password}) async {
    user_gateway.User user;
    try {
      user = await auth.signIn(email, password);
    } catch(e) {
      return Option<User>.none();
    }

    return Option<User>.of(
        User(
          id: user.id,
          name: user.displayName != null ? user.displayName! : "",
          email: user.email != null ? user.email! : "",
        )
    );
  }

  void logoutUser() {
    auth.signOut();
  }

  Future<void> deleteUser() async {
    await auth.deleteAccount();
  }
}
