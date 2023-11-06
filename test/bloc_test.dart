import 'package:clique_king_model/clique_king_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationRepository extends Mock implements AuthenticationRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockCliqueRepository extends Mock implements CliqueRepository {}

void main() async {

  group('Clique Bloc tests', () {
    final CliqueRepository cliqueRepository = MockCliqueRepository();
    final UserRepository userRepository = MockUserRepository();

    final UserId validId = "valid_id";
    final String validEmail = "valid@email.com";
    final String validUserName = "ValidUser";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);

    final String validCliqueName = "validCliqueName";
    final Clique validClique = Clique(name: validCliqueName, creatorId: validId);
    final CliqueId validCliqueId = validClique.id;

    final int scoreIncrease = 1;
    final Score score = Score.fromUser(validUser);
    final Score increasedScore = score.increaseScore(increase: scoreIncrease);

    final Score score1 = Score(userId: "userId1", userName: "userName1", score: 1);
    final Score score42 = Score(userId: "userId2", userName: "userName2", score: 42);
    final Score score5 = Score(userId: "userId3", userName: "userName3", score: 5);

    Stream<List<Score>> scoreStream() async* {
      yield [score1];
      yield [score1, score42];
      yield [score1, score42, score5];
    }

    setUpAll(() {
      reset(cliqueRepository);
      reset(userRepository);
    });

    blocTest(
      'Nothing emitted when created, initial state == CliqueInitial',
      build: () => CliqueBloc(
          cliqueRepository: cliqueRepository),
      expect: () => [],
      verify: (bloc) => bloc.state is CliqueInitial,
    );

    blocTest(
      'Emits CliqueLoadingSuccess on CliqueLoad Event',
      setUp: () {
        when(
          () => cliqueRepository.readScoresFromClique(cliqueId: validCliqueId),
        ).thenAnswer((_) => Either<RepositoryError, Stream<List<Score>>>.of(scoreStream()));
        when(
          () => cliqueRepository.getClique(cliqueId: validCliqueId),
        ).thenAnswer((_) => Future<Either<RepositoryError, Clique>>.value(Either.of(validClique)));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueLoad(cliqueId: validCliqueId)),
      expect: () => [
        CliqueLoadingInProgress(),
        CliqueLoadingSuccess(clique: validClique, allScoresSorted: [score1]),
        CliqueLoadingSuccess(clique: validClique, allScoresSorted: [score42, score1]),
        CliqueLoadingSuccess(clique: validClique, allScoresSorted: [score42, score5, score1])
      ],
      verify: (bloc) => bloc.state is CliqueLoadingSuccess,
    );

    blocTest(
      'Emits CliqueIncreaseScoreSuccess on CliqueIncreaseScore Event',
      setUp: () {
        when(
          () => cliqueRepository.getScore(cliqueId: validCliqueId, userId: validId),
        ).thenAnswer((_) => Future<Either<RepositoryError, Score>>.value(Either.of(score)));
        when(
          () => cliqueRepository.increaseScore(cliqueId: validCliqueId, score: score, scoreIncrease: scoreIncrease),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.none()));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueIncreaseScore(cliqueId: validCliqueId, user: validUser, increase: scoreIncrease)),
      expect: () => [CliqueIncreaseScoreInProgress(), CliqueIncreaseScoreSuccess()],
      verify: (bloc) => bloc.state is CliqueIncreaseScoreSuccess,
    );

    blocTest(
      'Emits CliqueJoinSuccess on CliqueJoin Event',
      setUp: () {
        when(
          () => cliqueRepository.addUser(cliqueId: validCliqueId, user: validUser),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.none()));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueJoin(cliqueId: validCliqueId, user: validUser)),
      expect: () => [CliqueJoinInProgress(), CliqueJoinSuccess()],
      verify: (bloc) => bloc.state is CliqueJoinSuccess,
    );

    blocTest(
      'Emits CliqueLeaveSuccess on CliqueLeave Event',
      setUp: () {
        when(
              () => cliqueRepository.removeUser(cliqueId: validCliqueId, userId: validId),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.none()));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueLeave(cliqueId: validCliqueId, user: validUser)),
      expect: () => [CliqueLeaveInProgress(), CliqueLeaveSuccess()],
      verify: (bloc) => bloc.state is CliqueLeaveSuccess,
    );

  });

  group('Cliques Bloc tests', () {
    final CliqueRepository cliqueRepository = MockCliqueRepository();
    final AuthenticationRepository authenticationRepository = MockAuthenticationRepository();

    final UserId validId = "valid_id";
    final String validEmail = "valid@email.com";
    final String validUserName = "ValidUser";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);

    final String validCliqueName1 = "validCliqueName1";
    final Clique validClique1 = Clique(name: validCliqueName1, creatorId: validId);
    final CliqueId validCliqueId1 = validClique1.id;

    final String validCliqueName2 = "validCliqueName2";
    final Clique validClique2 = Clique(name: validCliqueName2, creatorId: validId);
    final CliqueId validCliqueId2 = validClique2.id;

    Stream<List<Clique>> cliqueStream() async* {
      yield [validClique1];
      yield [validClique1, validClique2];
    }

    setUpAll(() {
      reset(cliqueRepository);
    });

    blocTest(
      'Nothing emitted when created, initial state == CliquesInitial',
      build: () => CliquesBloc(
          cliqueRepository: cliqueRepository,
          authenticationRepository: authenticationRepository),
      expect: () => [],
      verify: (bloc) => bloc.state is CliquesInitial,
    );

    blocTest(
      'Emits CliquesLoadingSuccess on CliquesLoadEvent',
      setUp: () {
        when(
          () => cliqueRepository.readAllCliques(),
        ).thenAnswer((_) => Either<RepositoryError, Stream<List<Clique>>>.of(cliqueStream()));
      },
      build: () => CliquesBloc(
          cliqueRepository: cliqueRepository,
          authenticationRepository: authenticationRepository),
      act: (bloc) => bloc.add(CliquesLoad()),
      expect: () => [
        CliquesLoadingInProgress(),
        CliquesLoadingSuccess(cliques: [validClique1]),
        CliquesLoadingSuccess(cliques: [validClique1, validClique2])
      ],
      verify: (bloc) => bloc.state is CliquesLoadingSuccess,
    );

    blocTest(
      'Emits AddCliqueSuccess on AddClique',
      setUp: () {
        when(
          () => cliqueRepository.createClique(name: validCliqueName1, creatorId: validId),
        ).thenAnswer((_) => Future<Either<RepositoryError, Clique>>.value(Either.of(validClique1)));

        when(
              () => authenticationRepository.getLoggedInUser(),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
      },
      build: () => CliquesBloc(
          cliqueRepository: cliqueRepository,
          authenticationRepository: authenticationRepository),
      act: (bloc) => bloc.add(AddClique(name: validCliqueName1)),
      expect: () => [AddCliqueInProgress(), AddCliqueSuccess(clique: validClique1)],
      verify: (bloc) => bloc.state is AddCliqueSuccess,
    );

    blocTest(
      'Emits RemoveCliqueSuccess on RemoveClique',
      setUp: () {
        when(
          () => cliqueRepository.deleteClique(cliqueId: validCliqueId1),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.none()));

        when(
              () => cliqueRepository.getClique(cliqueId: validCliqueId1),
        ).thenAnswer((_) => Future<Either<RepositoryError, Clique>>.value(Either.right(validClique1)));

        when(
              () => authenticationRepository.getLoggedInUser(),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
      },
      build: () => CliquesBloc(
          cliqueRepository: cliqueRepository,
          authenticationRepository: authenticationRepository),
      act: (bloc) => bloc.add(RemoveClique(cliqueId: validCliqueId1)),
      expect: () => [RemoveCliqueInProgress(), RemoveCliqueSuccess()],
      verify: (bloc) => bloc.state is RemoveCliqueSuccess,
    );

  });

  group('User Bloc tests', () {
    final AuthenticationRepository authenticationRepository = MockAuthenticationRepository();
    final UserRepository userRepository = MockUserRepository();

    final String validId = "valid_id";
    final String validEmail = "valid@email.com";
    final String invalidEmail = "invalid@email.com";
    final String validPassword = "valid_password";
    final String invalidPassword = "invalid_password";
    final String validUserName = "ValidUser";
    final String invalidUserName = "InvalidUser";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);
    final FailedToRegisterAccount failedToRegisterAccount = FailedToRegisterAccount(errorObject: "Failed to register.");
    final WrongLoginCredentials wrongLoginCredentials = WrongLoginCredentials(errorObject: "Wrong email or password.");
    final FailedToLogoutAccount failedToLogoutAccount = FailedToLogoutAccount(errorObject: "Failed to logout.");
    final FailedToDeleteAccount failedToDeleteAccount = FailedToDeleteAccount(errorObject: "Failed to delete.");
    final UserNameAlreadyInUse userNameAlreadyInUse = UserNameAlreadyInUse(errorObject: "User name is already in use.");

    setUp(() {
      reset(authenticationRepository);
      reset(userRepository);
    });

    blocTest(
      'Nothing emitted when created, initial state == UserInitial',
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      expect: () => [],
      verify: (bloc) => bloc.state is UserInitial,
    );

    blocTest(
      'Emits UserLoginSuccess on UserStarted Event (which should be sent on app startup)',
      setUp: () {
        when(
              () => authenticationRepository.isUserLoggedIn,
        ).thenReturn(true);
        when(
              () => authenticationRepository.getLoggedInUser(),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserStarted()),
      expect: () => [UserLoginInProgress(), UserLoginSuccess(user: validUser)],
      verify: (bloc) => bloc.state is UserLoginSuccess,
    );

    blocTest(
      'Emits UserRegisterSuccess on UserRegister Event',
      setUp: () {
        when(
              () => authenticationRepository.registerUser(email: validEmail, password: validPassword, userName: validUserName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
        when(
              () => userRepository.createUser(user: validUser),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
        when(
              () => userRepository.userExists(userName: validUserName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(false)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: validEmail, password: validPassword, name: validUserName)),
      expect: () => [UserRegisterInProgress(), UserRegisterSuccess(user: validUser)],
      verify: (bloc) => bloc.state is UserRegisterSuccess,
    );

    blocTest(
      'Emits UserRegisterFailure on UserRegister Event with invalid data',
      setUp: () {
        when(
              () => authenticationRepository.registerUser(email: invalidEmail, password: invalidPassword, userName: invalidUserName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(failedToRegisterAccount)));
        when(
              () => userRepository.userExists(userName: invalidUserName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(false)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: invalidEmail, password: invalidPassword, name: invalidUserName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure(error: failedToRegisterAccount)],
      verify: (bloc) => bloc.state is UserRegisterFailure,
    );

    blocTest(
      'Emits UserRegisterFailure on UserRegister Event with existing user name',
      setUp: () {
        when(
              () => authenticationRepository.registerUser(email: invalidEmail, password: invalidPassword, userName: invalidUserName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(failedToRegisterAccount)));
        when(
              () => userRepository.userExists(userName: invalidUserName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(true)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: invalidEmail, password: invalidPassword, name: invalidUserName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure(error: userNameAlreadyInUse)],
      verify: (bloc) => bloc.state is UserRegisterFailure,
    );

    blocTest(
      'Emits UserLoginSuccess on UserLogin Event',
      setUp: () {
        when(
              () => authenticationRepository.loginUser(email: validEmail, password: validPassword),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserLogin(email: validEmail, password: validPassword)),
      expect: () => [UserLoginInProgress(), UserLoginSuccess(user: validUser)],
      verify: (bloc) => bloc.state is UserLoginSuccess,
    );

    blocTest(
      'Emits UserLoginFailure on UserLogin Event with invalid data',
      setUp: () {
        when(
              () => authenticationRepository.loginUser(email: invalidEmail, password: invalidPassword),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(wrongLoginCredentials)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserLogin(email: invalidEmail, password: invalidPassword)),
      expect: () => [UserLoginInProgress(), UserLoginFailure(error: wrongLoginCredentials)],
      verify: (bloc) => bloc.state is UserLoginFailure,
    );

    blocTest(
      'Emits UserLogoutSuccess on UserLogout Event',
      setUp: () {
        when(
              () => authenticationRepository.logoutUser(),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option<RepositoryError>.none()));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserLogout()),
      expect: () => [UserLogoutInProgress(), UserLogoutSuccess()],
      verify: (bloc) => bloc.state is UserLogoutSuccess,
    );

    blocTest(
      'Emits UserLogoutFailure on UserLogout Event',
      setUp: () {
        when(
              () => authenticationRepository.logoutUser(),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option<RepositoryError>.of(failedToLogoutAccount)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserLogout()),
      expect: () => [UserLogoutInProgress(), UserLogoutFailure(error: failedToLogoutAccount)],
      verify: (bloc) => bloc.state is UserLogoutFailure,
    );

    blocTest(
      'Emits UserDeleteSuccess on UserDelete Event',
      setUp: () {
        when(
              () => authenticationRepository.deleteUser(),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.none()));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserDelete()),
      expect: () => [UserDeleteInProgress(), UserDeleteSuccess()],
      verify: (bloc) => bloc.state is UserDeleteSuccess,
    );

    blocTest(
      'Emits UserDeleteFailure on UserDelete Event invalid data',
      setUp: () {
        when(
              () => authenticationRepository.deleteUser(),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.of(failedToDeleteAccount)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserDelete()),
      expect: () => [UserDeleteInProgress(), UserDeleteFailure(error: failedToDeleteAccount)],
      verify: (bloc) => bloc.state is UserDeleteFailure,
    );

  });

}
