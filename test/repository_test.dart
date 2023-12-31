import 'package:clique_king_model/clique_king_model.dart';
import 'package:firedart/firedart.dart';
import 'package:firedart/auth/user_gateway.dart' as user_gateway;
import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements Firestore {}
class MockDocument extends Mock implements Document {}
class MockStream<T> extends Mock implements Stream<T> {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockCollectionReference extends Mock implements CollectionReference {}

void main() {

  group("Authentication Repository tests", () {
    final MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
    final AuthenticationRepository authenticationRepository = AuthenticationRepository(authentication: mockFirebaseAuth);

    final UserId validId = "valid_id";
    final String validEmail = "valid@email.com";
    final String invalidEmail = "invalid email";
    final String validPassword = "valid_password";
    final String invalidPassword = "invalid";
    final String validUserName = "ValidUser";
    final String invalidUserName = " ";
    final String validUpdateName = "ValidUpdatedName";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);
    final User updatedUser = User(id: validId, name: validUpdateName, email: validEmail);
    final User badUser = User(id: "bad_id", name: "bad_name", email: "bad_email");

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

    final Map<String, dynamic> userWithUpdatedNameMap = {
      'localId': validId,
      'displayName': validUpdateName,
      'photoUrl': null,
      'email': validEmail,
      'emailVerified': null,
    };

    final user_gateway.User authUserWithoutName = user_gateway.User.fromMap(userWithoutNameMap);
    final user_gateway.User authUserWithName = user_gateway.User.fromMap(userWithNameMap);
    final user_gateway.User authUserWithUpdatedName = user_gateway.User.fromMap(userWithUpdatedNameMap);

    setUp(() {
      reset(mockFirebaseAuth);
    });

    test("registerUser(), called with valid data, returns a valid User", () async {

      when(
              () => mockFirebaseAuth.signUp(validEmail, validPassword)
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithoutName));

      when(
              () => mockFirebaseAuth.updateProfile(displayName: validUserName)
      ).thenAnswer((_) => Future<void>.value());

      when(
              () => mockFirebaseAuth.getUser()
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithName));

      final Either<RepositoryError, User> result = await authenticationRepository.registerUser(
          email: validEmail,
          password: validPassword,
          userName: validUserName,
      );
      User user = result.getOrElse((l) => badUser);

      expect(user, equals(validUser));
    });

    test("registerUser(), called with invalid data, returns a RepositoryError", () async {

      final Either<RepositoryError, User> result = await authenticationRepository.registerUser(
          email: invalidEmail,
          password: invalidPassword,
          userName: invalidUserName,
      );

      expect(result.isLeft(), isTrue);
    });

    test("updateUser(), called with valid data, returns a updated User", () async {

      when(
              () => mockFirebaseAuth.updateProfile(displayName: validUpdateName)
      ).thenAnswer((_) => Future<void>.value());

      when(
              () => mockFirebaseAuth.getUser()
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithUpdatedName));

      final Either<RepositoryError, User> result = await authenticationRepository.updateUser(userName: validUpdateName);
      User user = result.getOrElse((l) => badUser);

      expect(user, equals(updatedUser));
    });

    test("getLoggedInUser(), called when user is logged in, returns a valid User", () async {

      when(
              () => mockFirebaseAuth.getUser()
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithName));

      final Either<RepositoryError, User> result = await authenticationRepository.getLoggedInUser();
      final User user = result.getOrElse((l) => badUser);

      expect(user, equals(validUser));
    });

    test("getLoggedInUser(), called when user is not logged in, returns a RepositoryError", () async {

      when(
              () => mockFirebaseAuth.getUser()
      ).thenThrow(Exception("Repository Error"));

      final Either<RepositoryError, User> result = await authenticationRepository.getLoggedInUser();

      expect(result.isLeft(), isTrue);
    });

    test("loginUser(), called with valid data, returns a valid User", () async {

      when(
        () => mockFirebaseAuth.signIn(validEmail, validPassword)
      ).thenAnswer((_) => Future<user_gateway.User>.value(authUserWithName));

      final Either<RepositoryError, User> result = await authenticationRepository.loginUser(
          email: validEmail,
          password: validPassword,
      );
      User user = result.getOrElse((l) => badUser);

      expect(user, equals(validUser));
    });

    test("loginUser(), called with invalid data, returns a RepositoryError", () async {

      when(
        () => mockFirebaseAuth.signIn(invalidEmail, invalidPassword)
      ).thenThrow(Exception("Repository Error"));

      final Either<RepositoryError, User> result = await authenticationRepository.loginUser(
        email: invalidEmail,
        password: invalidPassword,
      );

      expect(result.isLeft(), isTrue);
    });

    test("logoutUser(), called, FirebaseAuth.signOut() is called", () async {

      when(
        () => mockFirebaseAuth.signOut()
      ).thenAnswer((_) => {});

      Option<RepositoryError> result = await authenticationRepository.logoutUser();

      verify(() => mockFirebaseAuth.signOut());
      expect(result.isNone(), isTrue);
    });

    test("deleteUser(), called, FirebaseAuth.deleteAccount() is called", () async {

      when(
        () => mockFirebaseAuth.deleteAccount()
      ).thenAnswer((_) => Future<void>.value());

      Option<RepositoryError> result = await authenticationRepository.deleteUser();

      verify(() => mockFirebaseAuth.deleteAccount());
      expect(result.isNone(), isTrue);
    });

  });

  group("User Repository tests", () {
    final MockFirestore mockFirestore = MockFirestore();
    final UserRepository userRepository = UserRepository(store: mockFirestore);
    final MockDocument mockUserDocument = MockDocument();
    final MockDocument mockUpdatedUserDocument = MockDocument();
    final MockCollectionReference mockUserCollectionReference = MockCollectionReference();
    final MockDocumentReference mockUserDocumentReference = MockDocumentReference();
    final MockDocumentReference mockToBeUpdatedUserDocumentReference = MockDocumentReference();


    final UserId validId = "valid_id";
    final String validEmail = "valid@email.com";
    final String validUserName = "ValidUser";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);
    final Map<String, dynamic> validUserMap = validUser.toMap();

    final String validToBeUpdatedId = "valid_update_id";

    final String validUpdatedUserName = "ValidUserUpdated";

    final User validUpdatedUser = User(id: validToBeUpdatedId, name: validUpdatedUserName, email: validEmail);
    final Map<String, dynamic> validUpdatedUserMap = validUpdatedUser.toMap();

    setUp(() {
      reset(mockFirestore);
      reset(mockUserDocument);
      reset(mockUpdatedUserDocument);
      reset(mockUserCollectionReference);
      reset(mockUserDocumentReference);
      reset(mockToBeUpdatedUserDocumentReference);

      when(
        () => mockFirestore.collection(userCollection)
      ).thenReturn(mockUserCollectionReference);

      when(
        () => mockUserCollectionReference.document(validId)
      ).thenReturn(mockUserDocumentReference);

      when(
        () => mockUserCollectionReference.document(validToBeUpdatedId)
      ).thenReturn(mockToBeUpdatedUserDocumentReference);

      when(
        () => mockUserDocumentReference.create(validUserMap)
      ).thenAnswer((_) => Future<Document>.value(mockUserDocument));

      when(
        () => mockUserDocumentReference.get()
      ).thenAnswer((_) => Future<Document>.value(mockUserDocument));

      when(
        () => mockUserDocumentReference.delete()
      ).thenAnswer((_) => Future<void>.value());

      when(
        () => mockToBeUpdatedUserDocumentReference.update(validUpdatedUserMap)
      ).thenAnswer((_) => Future<void>.value());

      when(
        () => mockToBeUpdatedUserDocumentReference.get()
      ).thenAnswer((_) => Future<Document>.value(mockUpdatedUserDocument));
      
      when(
        () => mockUserDocument.map
      ).thenReturn(validUserMap);

      when(
        () => mockUpdatedUserDocument.map
      ).thenReturn(validUpdatedUserMap);

    });

    test("createUser(), called with valid data, returns a valid User", () async {
      Either<RepositoryError, User> result = await userRepository.createUser(user: validUser);
      User user = result.getOrElse((l) => throw Exception(l.errorObject));

      verify(() => mockUserDocumentReference.create(any()));
      expect(user, equals(validUser));
    });

    test("readUser(), called with valid data, returns a valid User", () async {
      Either<RepositoryError, User> result = await userRepository.readUser(id: validId);
      User user = result.getOrElse((l) => throw Exception(l.errorObject));

      verify(() => mockUserDocumentReference.get());
      expect(user, equals(validUser));
    });

    test("updateUser(), called with valid data, returns a valid User", () async {

      Either<RepositoryError, User> result = await userRepository.updateUser(user: validUpdatedUser);
      User user = result.getOrElse((l) => throw Exception(l.errorObject));

      verify(() => mockToBeUpdatedUserDocumentReference.update(any()));
      expect(user, equals(validUpdatedUser));
    });

    test("deleteUser(), called with valid data, returns no RepositoryError", () async {
      Option<RepositoryError> result = await userRepository.deleteUser(id: validId);

      verify(() => mockUserDocumentReference.delete());
      expect(result.isNone(), isTrue);
    });

  });

  group("Clique Repository tests", () {
    final MockFirestore mockFirestore = MockFirestore();
    final CliqueRepository cliqueRepository = CliqueRepository(store: mockFirestore);
    final MockDocument mockCliqueDocument = MockDocument();
    final MockDocument mockScoreDocument = MockDocument();
    final MockStream<List<Document>> mockCliqueStream = MockStream<List<Document>>();
    final MockStream<List<Document>> mockScoreStream = MockStream<List<Document>>();
    final MockDocumentReference mockCliqueDocumentReference = MockDocumentReference();
    final MockDocumentReference mockScoreDocumentReference = MockDocumentReference();
    final MockCollectionReference mockCliqueCollectionReference = MockCollectionReference();
    final MockCollectionReference mockScoreCollectionReference = MockCollectionReference();

    final UserId validId = "valid_id";
    final String validEmail = "valid@email.com";
    final String validUserName = "ValidUser";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);

    final Score validScore = Score(userId: validId, userName: validUserName, score: 0);
    final Map<String, dynamic> validScoreMap = validScore.toMap();
    final int increase = 1;
    final Score validScoreIncreased = validScore.increaseScore(increase: increase);
    final Map<String, dynamic> validScoreIncreasedMap = validScoreIncreased.toMap();

    final String validCliqueName = "validCliqueName";
    final Clique validClique = Clique(name: validCliqueName, creatorId: validId);
    final CliqueId validCliqueId = validClique.id;
    final Map<String, dynamic> validCliqueMap = validClique.toMap();

    Stream<List<Document>> cliqueDocumentStream() async* {
      yield [mockCliqueDocument];
    }

    Stream<List<Document>> scoreDocumentStream() async* {
      yield [mockScoreDocument];
    }

    setUp(() {
      reset(mockFirestore);
      reset(mockCliqueDocument);
      reset(mockScoreDocument);
      reset(mockCliqueStream);
      reset(mockScoreStream);
      reset(mockCliqueDocumentReference);
      reset(mockScoreDocumentReference);
      reset(mockCliqueCollectionReference);
      reset(mockScoreCollectionReference);

      when(
        () => mockFirestore.collection(cliqueCollection)
      ).thenReturn(mockCliqueCollectionReference);

      when(
        () => mockCliqueCollectionReference.document(any())
      ).thenReturn(mockCliqueDocumentReference);

      when(
        () => mockCliqueDocumentReference.collection(any())
      ).thenReturn(mockScoreCollectionReference);

      when(
        () => mockCliqueDocumentReference.delete()
      ).thenAnswer((_) => Future<void>.value());

      when(
        () => mockCliqueDocumentReference.create(any())
      ).thenAnswer((_) => Future<Document>.value(mockCliqueDocument));

      when(
        () => mockCliqueDocumentReference.get()
      ).thenAnswer((_) => Future<Document>.value(mockCliqueDocument));

      when(
        () => mockScoreCollectionReference.document(validId)
      ).thenReturn(mockScoreDocumentReference);

      when(
        () => mockScoreDocumentReference.create(any())
      ).thenAnswer((_) => Future<Document>.value(mockScoreDocument));

      when(
        () => mockScoreDocumentReference.delete()
      ).thenAnswer((_) => Future<void>.value());

      when(
        () => mockScoreDocumentReference.update(validScoreIncreasedMap)
      ).thenAnswer((_) => Future<void>.value());

      when(
        () => mockScoreDocumentReference.get()
      ).thenAnswer((_) => Future<Document>.value(mockScoreDocument));

      when(
        () => mockCliqueCollectionReference.stream
      ).thenAnswer((_) => cliqueDocumentStream());

      when(
          () => mockScoreCollectionReference.stream
      ).thenAnswer((_) => scoreDocumentStream());

      when(
        () => mockCliqueDocument.map
      ).thenReturn(validCliqueMap);

      when(
        () => mockScoreDocument.map
      ).thenReturn(validScoreMap);

    });

    test("createClique(), called with valid data, document.create() is called and returns a valid Clique", () async {
      Either<RepositoryError, Clique> result = await cliqueRepository.createClique(name: validCliqueName, creatorId: validId);
      Clique clique = result.getOrElse((l) => throw Exception("Not a valid Clique! Error: ${l.errorObject}"));

      verify(() => mockCliqueDocumentReference.create(any()));
      expect(clique, validClique);
    });

    test("readAllCliques(), called, gets collection.stream and returns a Stream<List<Clique>>", () async {
      Either<RepositoryError, Stream<List<Clique>>> result = cliqueRepository.readAllCliques();

      Stream<List<Clique>> cliqueStream = result.getOrElse((l) => throw Exception("Not a valid Clique Stream! Error: ${l.errorObject}"));
      List<Clique> cliques = await cliqueStream.first;

      verify(() => mockCliqueCollectionReference.stream);
      expect(result.isRight(), isTrue);
      expect(cliques, [validClique]);
    });

    test("readScoresFromClique(), called with valid data, returns a Stream<List<Score>>", () async {
      Either<RepositoryError, Stream<List<Score>>> result = cliqueRepository.readScoresFromClique(cliqueId: validCliqueId);

      Stream<List<Score>> scoreStream = result.getOrElse((l) => throw Exception("Not a valid Clique Stream! Error: ${l.errorObject}"));
      List<Score> scores = await scoreStream.first;

      verify(() => mockScoreCollectionReference.stream);
      expect(result.isRight(), isTrue);
      expect(scores, [validScore]);
    });

    test("addUser(), called with valid data, document.create() is called and returns no RepositoryError", () async {
      Option<RepositoryError> result = await cliqueRepository.addUser(cliqueId: validCliqueId, user: validUser);

      verify(() => mockScoreDocumentReference.create(any()));
      expect(result.isNone(), isTrue);
    });

    test("removeUser(), called with valid data, document.delete() is called and returns no RepositoryError", () async {
      final Option<RepositoryError> result = await cliqueRepository.removeUser(cliqueId: validCliqueId, userId: validId);

      verify(() => mockScoreDocumentReference.delete());
      expect(result.isNone(), isTrue);
    });

    test("deleteClique(), called with valid data, collection.delete() is called and returns no RepositoryError", () async {
      final Option<RepositoryError> result = await cliqueRepository.deleteClique(cliqueId: validCliqueId);

      verify(() => mockCliqueDocumentReference.delete());
      expect(result.isNone(), isTrue);
    });

    test("getClique(), called with valid data, collection.get() is called and returns a valid Clique", () async {
      final Either<RepositoryError, Clique> result = await cliqueRepository.getClique(cliqueId: validCliqueId);

      Clique clique = result.getOrElse((l) => throw Exception("Not a valid Clique! Error: ${l.errorObject}"));

      verify(() => mockCliqueDocumentReference.get());
      expect(result.isRight(), isTrue);
      expect(clique, validClique);
    });

    test("increaseScore(), called with valid data, document.update() is called and returns no RepositoryError", () async {
      final Option<RepositoryError> result = await cliqueRepository.increaseScore(cliqueId: validCliqueId, score: validScore, scoreIncrease: increase);

      verify(() => mockScoreDocumentReference.update(any()));
      expect(result.isNone(), isTrue);
    });

    test("getScore(), called with valid data, document.get() is called and returns a valid Score", () async {
      final Either<RepositoryError, Score> result = await cliqueRepository.getScore(cliqueId: validCliqueId, userId: validId);

      Score score = result.getOrElse((l) => throw Exception("Not a valid Score! Error: ${l.errorObject}"));

      verify(() => mockScoreDocumentReference.get());
      expect(result.isRight(), isTrue);
      expect(score, equals(validScore));
    });

  });

}