import 'package:clique_king_model/clique_king_model.dart';
import 'package:firedart/firedart.dart';
import 'package:firedart/auth/user_gateway.dart' as user_gateway;
import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements Firestore {}

void main() {

  group("Authentication Repository tests", () {
    final MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
    final AuthenticationRepository authenticationRepository = AuthenticationRepository(authentication: mockFirebaseAuth);

    final String validId = "valid_id";
    final String validEmail = "valid@email.com";
    final String invalidEmail = "invalid@email.com";
    final String validPassword = "valid_password";
    final String invalidPassword = "invalid_password";
    final String validUserName = "ValidUser";
    final String invalidUserName = "InvalidUser";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);

    final Map<String, dynamic> userWithoutNameMap = {
      'localId': validId,
      'displayName': null,
      'photoUrl': null,
      'email': validEmail,
      'emailVerified': null,
    };

    final Map<String, dynamic> userWithNameMap = {
      'localId': validId,
      'displayName': validUserName,
      'photoUrl': null,
      'email': validEmail,
      'emailVerified': null,
    };

    final user_gateway.User authUserWithoutName = user_gateway.User.fromMap(userWithoutNameMap);
    final user_gateway.User authUserWithName = user_gateway.User.fromMap(userWithNameMap);

    setUp(() {
      reset(mockFirebaseAuth);

      when(
        () => mockFirebaseAuth.signUp(validEmail, validPassword)
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithoutName));

      when(
        () => mockFirebaseAuth.updateProfile(displayName: validUserName)
      ).thenAnswer((_) => Future<void>.value());

      when(
        () => mockFirebaseAuth.getUser()
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithName));

      when(
        () => mockFirebaseAuth.signUp(invalidEmail, invalidPassword)
      ).thenThrow(Exception("Repository Error"));

      when(
        () => mockFirebaseAuth.signIn(validEmail, validPassword)
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithName));

      when(
        () => mockFirebaseAuth.signIn(invalidEmail, invalidPassword)
      ).thenThrow(Exception("Repository Error"));

      when(
        () => mockFirebaseAuth.signOut()
      ).thenAnswer((_) => {});

      when(
        () => mockFirebaseAuth.deleteAccount()
      ).thenAnswer((_) => Future<void>.value());

    });

    test("registerUser(), called with valid data, returns a valid User", () async {

      final Either<RepositoryError, User> result = await authenticationRepository.registerUser(
          email: validEmail,
          password: validPassword,
          userName: validUserName,
      );
      User user = result.getOrElse((l) => throw Exception("Not a valid User"));

      expect(user, equals(validUser));
    });

    test("registerUser(), called with invalid data, returns a RepositoryError", () async {

      final Either<RepositoryError, User> result = await authenticationRepository.registerUser(
          email: invalidEmail,
          password: invalidPassword,
          userName: invalidUserName,
      );
      RepositoryError error = result.getLeft().getOrElse(() => throw Exception("Not a RepositoryError"));

      expect(error, isA<RepositoryError>());
    });

    test("loginUser(), called with valid data, returns a valid User", () async {

      final Either<RepositoryError, User> result = await authenticationRepository.loginUser(
          email: validEmail,
          password: validPassword,
      );
      User user = result.getOrElse((l) => throw Exception("Not a valid User"));

      expect(user, equals(validUser));
    });

    test("loginUser(), called with invalid data, returns a RepositoryError", () async {

      final Either<RepositoryError, User> result = await authenticationRepository.loginUser(
        email: invalidEmail,
        password: invalidPassword,
      );
      RepositoryError error = result.getLeft().getOrElse(() => throw Exception("Not a RepositoryError"));

      expect(error, isA<RepositoryError>());
    });

    test("logoutUser(), called, FirebaseAuth.signOut() is called", () {

      authenticationRepository.logoutUser();

      verify(() => mockFirebaseAuth.signOut());
    });

    test("deleteUser(), called, FirebaseAuth.deleteAccount() is called", () async {

      await authenticationRepository.deleteUser();

      verify(() => mockFirebaseAuth.deleteAccount());
    });

  });

  // group("User Repository tests", () {
  //
  //   test("", () {
  //
  //   });
  //
  //   test("", () {
  //
  //   });
  //
  //   test("", () {
  //
  //   });
  //
  // });

  group("Clique Repository tests", () {
    // final MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
    final MockFirestore mockFirestore = MockFirestore();
    // final AuthenticationRepository authenticationRepository = AuthenticationRepository(auth: mockFirebaseAuth);
    final CliqueRepository cliqueRepository = CliqueRepository(store: mockFirestore);

    final String validCliqueName = "validCliqueName";

    final Clique validClique = Clique(name: validCliqueName);

    // void createClique(String name)
    test("createClique(), called with valid data, Firestore.collection().add() is called", () {
      cliqueRepository.createClique(name: validCliqueName);
      verify(() => mockFirestore.collection(validCliqueName).add(validClique.toMap()));
    });

    //   StreamSubscription<List<Document>> readAllCliques({required List<Clique> Function(List<Document> event) handler})
    test("readAllCliques(), called, returns a stream subscription", () {

    });

    //  List<Document> readScoresFromClique({ required String cliqueId, required List<Score> Function(List<Document> event) handler})
    test("readScoresFromClique(), called with valid data, returns ", () {

    });

    // void addUser(String cliqueId, String userId, String userName)
    test("addUser(), called with valid data", () {

    });

    // void removeUser(String cliqueId, String userId)
    test("", () {

    });

    // void deleteClique(String cliqueId)
    test("", () {

    });

  });

}