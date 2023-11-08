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

    final UserId validId = "valid_id";
    final UserId invalidId = "invalid_id";
    final String validEmail = "valid@email.com";
    final String invalidEmail = "invalid@email.com";
    final String validUserName = "ValidUser";
    final String invalidUserName = "InvalidUser";

    final User validUser = User(id: validId, name: validUserName, email: validEmail);
    final User invalidUser = User(id: invalidId, name: invalidUserName, email: invalidEmail);

    final String validCliqueName = "validCliqueName";
    final Clique validClique = Clique(name: validCliqueName, creatorId: validId);
    final CliqueId validCliqueId = validClique.id;
    final String invalidCliqueId = "validCliqueId";

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

    final FailedToReadClique failedToReadClique = FailedToReadClique(errorObject: "Failed to read clique.");
    final FailedToReadScore failedToReadScore = FailedToReadScore(errorObject: "Failed to read score.");
    final FailedToIncreaseScore failedToIncreaseScore = FailedToIncreaseScore(errorObject: "Failed to increase score.");
    final FailedToAddUserToClique failedToAddUserToClique = FailedToAddUserToClique(errorObject: "Failed to add user to clique.");
    final FailedToRemoveUserFromClique failedToRemoveUserFromClique = FailedToRemoveUserFromClique(errorObject: "Failed to remove user from clique.");

    setUp(() {
      reset(cliqueRepository);
    });

    blocTest(
      'InitialState, bloc created, Nothing emitted and state is CliqueInitial',
      build: () => CliqueBloc(
          cliqueRepository: cliqueRepository),
      expect: () => [],
      verify: (bloc) => bloc.state is CliqueInitial,
    );

    blocTest(
      'CliqueLoad, valid data, Emits CliqueLoadingSuccess and with all scores sorted',
      setUp: () {
        when(
              () => cliqueRepository.getClique(cliqueId: validCliqueId),
        ).thenAnswer((_) => Future<Either<RepositoryError, Clique>>.value(Either.of(validClique)));

        when(
              () => cliqueRepository.readScoresFromClique(cliqueId: validCliqueId),
        ).thenAnswer((_) => Either<RepositoryError, Stream<List<Score>>>.of(scoreStream()));
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
      'CliqueLoad, invalid data, Emits CliqueLoadingFailure',
      setUp: () {
        when(
              () => cliqueRepository.getClique(cliqueId: invalidCliqueId),
        ).thenAnswer((_) => Future<Either<RepositoryError, Clique>>.value(Either.left(failedToReadClique)));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueLoad(cliqueId: invalidCliqueId)),
      expect: () => [CliqueLoadingInProgress(),CliqueLoadingFailure(error: failedToReadClique)],
      verify: (bloc) => bloc.state is CliqueLoadingFailure,
    );

    blocTest(
      'CliqueIncreaseScore, valid data, Emits CliqueIncreaseScoreSuccess',
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
      'CliqueIncreaseScore, invalid data, Emits CliqueIncreaseScoreFailure',
      setUp: () {
        when(
              () => cliqueRepository.getScore(cliqueId: invalidCliqueId, userId: invalidId),
        ).thenAnswer((_) => Future<Either<RepositoryError, Score>>.value(Either.left(failedToReadScore)));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueIncreaseScore(cliqueId: invalidCliqueId, user: invalidUser, increase: scoreIncrease)),
      expect: () => [CliqueIncreaseScoreInProgress(), CliqueIncreaseScoreFailure(error: failedToReadScore)],
      verify: (bloc) => bloc.state is CliqueIncreaseScoreFailure,
    );

    blocTest(
      'CliqueIncreaseScore, clique repository failure, Emits CliqueIncreaseScoreFailure',
      setUp: () {
        when(
              () => cliqueRepository.getScore(cliqueId: validCliqueId, userId: validId),
        ).thenAnswer((_) => Future<Either<RepositoryError, Score>>.value(Either.of(score)));

        when(
              () => cliqueRepository.increaseScore(cliqueId: validCliqueId, score: score, scoreIncrease: scoreIncrease),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.of(failedToIncreaseScore)));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueIncreaseScore(cliqueId: validCliqueId, user: validUser, increase: scoreIncrease)),
      expect: () => [CliqueIncreaseScoreInProgress(), CliqueIncreaseScoreFailure(error: failedToIncreaseScore)],
      verify: (bloc) => bloc.state is CliqueIncreaseScoreFailure,
    );

    blocTest(
      'CliqueJoin, valid data, Emits CliqueJoinSuccess',
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
      'CliqueJoin, invalid data, Emits CliqueJoinFailure',
      setUp: () {
        when(
              () => cliqueRepository.addUser(cliqueId: invalidCliqueId, user: invalidUser),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.of(failedToAddUserToClique)));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueJoin(cliqueId: invalidCliqueId, user: invalidUser)),
      expect: () => [CliqueJoinInProgress(), CliqueJoinFailure(error: failedToAddUserToClique)],
      verify: (bloc) => bloc.state is CliqueJoinFailure,
    );

    blocTest(
      'CliqueLeave, valid data, Emits CliqueLeaveSuccess',
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

    blocTest(
      'CliqueLeave, invalid data, Emits CliqueLeaveFailure',
      setUp: () {
        when(
              () => cliqueRepository.removeUser(cliqueId: invalidCliqueId, userId: invalidId),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.of(failedToRemoveUserFromClique)));
      },
      build: () => CliqueBloc(cliqueRepository: cliqueRepository),
      act: (bloc) => bloc.add(CliqueLeave(cliqueId: invalidCliqueId, user: invalidUser)),
      expect: () => [CliqueLeaveInProgress(), CliqueLeaveFailure(error: failedToRemoveUserFromClique)],
      verify: (bloc) => bloc.state is CliqueLeaveFailure,
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

    setUp(() {
      reset(cliqueRepository);
      reset(authenticationRepository);
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
    final String validName = "ValidUser";
    final String invalidName = "InvalidUser";
    final String existingName = "ExistingUser";
    final String validUpdateName = "UpdatedName";
    final String invalidUpdateName = "InvalidUpdatedName";

    final User validUser = User(id: validId, name: validName, email: validEmail);
    final User updatedUser = User(id: validId, name: validUpdateName, email: validEmail);

    final AccountNotLoggedIn accountNotLoggedIn = AccountNotLoggedIn(errorObject: "User is not logged in");
    final FailedToRegisterAccount failedToRegisterAccount = FailedToRegisterAccount(errorObject: "Failed to register account.");
    final InvalidUserName invalidUserName = InvalidUserName(errorObject: "Invalid user name.");
    final FailedToQueryUsers failedToQueryUsers = FailedToQueryUsers(errorObject: "Failed to query users.");
    final FailedToCreateUser failedToCreateUser = FailedToCreateUser(errorObject: "Failed to create user.");
    final FailedToUpdateUser failedToUpdateUser = FailedToUpdateUser(errorObject: "Failed to update user.");
    final WrongLoginCredentials wrongLoginCredentials = WrongLoginCredentials(errorObject: "Wrong email or password.");
    final FailedToLogoutAccount failedToLogoutAccount = FailedToLogoutAccount(errorObject: "Failed to logout.");
    final FailedToDeleteAccount failedToDeleteAccount = FailedToDeleteAccount(errorObject: "Failed to delete account.");
    final FailedToDeleteUser failedToDeleteUser = FailedToDeleteUser(errorObject: "Failed to delete user.");
    final FailedToGetAccount failedToGetAccount = FailedToGetAccount(errorObject: "Failed to get logged in user.");
    final UserNameAlreadyInUse userNameAlreadyInUse = UserNameAlreadyInUse(errorObject: "User name is already in use.");

    setUp(() {
      reset(authenticationRepository);
      reset(userRepository);
    });

    blocTest(
      'InitialState, bloc created, Nothing emitted and state is UserInitial',
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      expect: () => [],
      verify: (bloc) => bloc.state is UserInitial,
    );

    blocTest(
      'UserStarted, app startup with authentication token, Emits UserLoginSuccess',
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
      'UserStarted, app startup without authentication token, Emits UserLoginFailure',
      setUp: () {
        when(
              () => authenticationRepository.isUserLoggedIn,
        ).thenReturn(false);
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserStarted()),
      expect: () => [UserLoginInProgress(), UserLoginFailure(error: accountNotLoggedIn)],
      verify: (bloc) => bloc.state is UserLoginFailure,
    );

    blocTest(
      'UserRegister, valid data, Emits UserRegisterSuccess',
      setUp: () {
        when(
              () => userRepository.userExists(userName: validName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(false)));

        when(
              () => authenticationRepository.registerUser(email: validEmail, password: validPassword, userName: validName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));

        when(
              () => userRepository.createUser(user: validUser),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: validEmail, password: validPassword, name: validName)),
      expect: () => [UserRegisterInProgress(), UserRegisterSuccess(user: validUser)],
      verify: (bloc) => bloc.state is UserRegisterSuccess,
    );

    blocTest(
      'UserRegister, invalid user name, Emits UserRegisterFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: invalidName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.left(invalidUserName)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: validEmail, password: validPassword, name: invalidName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure(error: invalidUserName)],
      verify: (bloc) => bloc.state is UserRegisterFailure,
    );

    blocTest(
      'UserRegister, failed to query if user exists, Emits UserRegisterFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: validName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.left(failedToQueryUsers)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: validName, password: validPassword, name: validName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure(error: failedToQueryUsers)],
      verify: (bloc) => bloc.state is UserRegisterFailure,
    );

    blocTest(
      'UserRegister, existing user name, Emits UserRegisterFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: existingName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(true)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: validEmail, password: validPassword, name: existingName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure(error: userNameAlreadyInUse)],
      verify: (bloc) => bloc.state is UserRegisterFailure,
    );

    blocTest(
      'UserRegister, invalid data, Emits UserRegisterFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: invalidName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(false)));

        when(
              () => authenticationRepository.registerUser(email: invalidEmail, password: invalidPassword, userName: invalidName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(failedToRegisterAccount)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: invalidEmail, password: invalidPassword, name: invalidName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure(error: failedToRegisterAccount)],
      verify: (bloc) => bloc.state is UserRegisterFailure,
    );

    blocTest(
      'UserRegister, user repository failure, Emits UserRegisterFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: validName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(false)));

        when(
              () => authenticationRepository.registerUser(email: validEmail, password: validPassword, userName: validName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));

        when(
              () => userRepository.createUser(user: validUser),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(failedToCreateUser)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: validEmail, password: validPassword, name: validName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure(error: failedToCreateUser)],
      verify: (bloc) => bloc.state is UserRegisterFailure,
    );

    blocTest(
      'UserUpdate, valid data, Emits UserUpdateSuccess',
      setUp: () {
        when(
              () => userRepository.userExists(userName: validUpdateName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(false)));

        when(
              () => authenticationRepository.updateUser(userName: validUpdateName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(updatedUser)));

        when(
              () => userRepository.updateUser(user: updatedUser),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(updatedUser)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserUpdate(name: validUpdateName)),
      expect: () => [UserUpdateInProgress(), UserUpdateSuccess(user: updatedUser)],
      verify: (bloc) => bloc.state is UserUpdateSuccess,
    );

    blocTest(
      'UserUpdate, invalid user name, Emits UserUpdateFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: invalidUpdateName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.left(invalidUserName)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserUpdate(name: invalidUpdateName)),
      expect: () => [UserUpdateInProgress(), UserUpdateFailure(error: invalidUserName)],
      verify: (bloc) => bloc.state is UserUpdateFailure,
    );

    blocTest(
      'UserUpdate, failed to query if user exists, Emits UserUpdateFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: validUpdateName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.left(failedToQueryUsers)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserUpdate(name: validUpdateName)),
      expect: () => [UserUpdateInProgress(), UserUpdateFailure(error: failedToQueryUsers)],
      verify: (bloc) => bloc.state is UserUpdateFailure,
    );

    blocTest(
      'UserUpdate, existing user name, Emits UserUpdateFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: existingName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(true)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserUpdate(name: existingName)),
      expect: () => [UserUpdateInProgress(), UserUpdateFailure(error: userNameAlreadyInUse)],
      verify: (bloc) => bloc.state is UserUpdateFailure,
    );

    blocTest(
      'UserUpdate, user repository failure, Emits UserUpdateFailure',
      setUp: () {
        when(
              () => userRepository.userExists(userName: validUpdateName),
        ).thenAnswer((_) => Future<Either<RepositoryError, bool>>.value(Either.right(false)));

        when(
              () => authenticationRepository.updateUser(userName: validUpdateName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(updatedUser)));

        when(
              () => userRepository.updateUser(user: updatedUser),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(failedToUpdateUser)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserUpdate(name: validUpdateName)),
      expect: () => [UserUpdateInProgress(), UserUpdateFailure(error: failedToUpdateUser)],
      verify: (bloc) => bloc.state is UserUpdateFailure,
    );

    blocTest(
      'UserLogin, valid login credentials, Emits UserLoginSuccess',
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
      'UserLogin, invalid login credentials, Emits UserLoginFailure',
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
      'UserLogout, no repository errors, Emits UserLogoutSuccess',
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
      'UserLogout, unable to log out user, Emits UserLogoutFailure',
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
      'UserDelete, no repository errors, Emits UserDeleteSuccess',
      setUp: () {
        when(
              () => authenticationRepository.getLoggedInUser(),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));

        when(
              () => userRepository.deleteUser(id: validId),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.none()));

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
      'UserDelete, unable to delete user account, Emits UserDeleteFailure',
      setUp: () {
        when(
              () => authenticationRepository.getLoggedInUser(),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));

        when(
              () => userRepository.deleteUser(id: validId),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.none()));

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

    blocTest(
      'UserDelete, unable to delete user, Emits UserDeleteFailure',
      setUp: () {
        when(
              () => authenticationRepository.getLoggedInUser(),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));

        when(
              () => userRepository.deleteUser(id: validId),
        ).thenAnswer((_) => Future<Option<RepositoryError>>.value(Option.of(failedToDeleteUser)));

      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserDelete()),
      expect: () => [UserDeleteInProgress(), UserDeleteFailure(error: failedToDeleteUser)],
      verify: (bloc) => bloc.state is UserDeleteFailure,
    );

    blocTest(
      'UserDelete, user not logged in, Emits UserDeleteFailure',
      setUp: () {
        when(
              () => authenticationRepository.getLoggedInUser(),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(failedToGetAccount)));

      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserDelete()),
      expect: () => [UserDeleteInProgress(), UserDeleteFailure(error: failedToGetAccount)],
      verify: (bloc) => bloc.state is UserDeleteFailure,
    );

  });

}
