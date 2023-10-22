import 'package:clique_king_model/clique_king_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationRepository extends Mock implements AuthenticationRepository {}
class MockUserRepository extends Mock implements UserRepository {}

void main() async {

  // group('Clique Bloc tests', () {
  //   late AuthenticationRepository authenticationRepository;
  //   late UserRepository userRepository;
  //   setUpAll(() async {
  //     final env = DotEnv(includePlatformEnvironment: true)..load();
  //     String? apiKey = env['FIREBASE_API_KEY'];
  //     String? projectId = env['FIREBASE_PROJECT_ID'];
  //
  //     if (apiKey == null) {
  //       print("FIREBASE_API_KEY missing from .env file");
  //       exit(0);
  //     }
  //
  //     if (projectId == null) {
  //       print("FIREBASE_PROJECT_ID missing from .env file");
  //       exit(0);
  //     }
  //
  //     FirebaseAuth.initialize(
  //         apiKey, await HiveStore.create(path: Directory.current.path));
  //     Firestore.initialize(projectId);
  //     authenticationRepository =
  //         AuthenticationRepository(auth: FirebaseAuth.instance);
  //     userRepository = UserRepository(store: Firestore.instance);
  //   });
  //
  //
  // });

  // group('Cliques Bloc tests', () {
  //
  //   setUpAll(() {
  //
  //   });
  //
  //   tearDownAll(() {
  //
  //   });
  //
  //   setUp(() {
  //
  //   });
  //
  //   tearDown(() {
  //
  //   });
  //
  //   blocTest(
  //     '',
  //     build: () => {},
  //     act: (bloc) => {},
  //     expect: () => {},
  //     verify: (bloc) => {},
  //   );
  //
  // });

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
    final RepositoryError repositoryError = RepositoryError(errorObject: Exception("Repository Error"));

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
      'Emits UserLoginInProgress on UserStarted Event (which should be sent on app startup)',
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserStarted()), // UserStarted is a Naming Convention
      expect: () => [UserLoginInProgress()], // why userstarted -> userlogin?
      // try login using local token if exists?
    );

    blocTest(
      'Emits UserRegisterSuccess on UserRegister Event',
      setUp: () {
        when(
            () => authenticationRepository.registerUser(email: validEmail, password: validPassword, userName: validUserName),
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.right(validUser)));
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
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(repositoryError)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserRegister(email: invalidEmail, password: invalidPassword, name: invalidUserName)),
      expect: () => [UserRegisterInProgress(), UserRegisterFailure()],
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
        ).thenAnswer((_) => Future<Either<RepositoryError, User>>.value(Either.left(repositoryError)));
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserLogin(email: invalidEmail, password: invalidPassword)),
      expect: () => [UserLoginInProgress(), UserLoginFailure()],
      verify: (bloc) => bloc.state is UserLoginFailure,
    );

    blocTest(
      'Emits UserLogoutSuccess on UserLogout Event',
      setUp: () {
        when(
              () => authenticationRepository.logoutUser(),
        ).thenAnswer((_) => Option<RepositoryError>.none());
      },
      build: () => UserBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository),
      act: (bloc) => bloc.add(UserLogout()),
      expect: () => [UserLogoutSuccess()],
      verify: (bloc) => bloc.state is UserLogoutSuccess,
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
      expect: () => [UserDeleteSuccess()],
      verify: (bloc) => bloc.state is UserDeleteSuccess,
    );

    // blocTest(
    //   'Emits UserDeleteFailure on UserDelete Event invalid data',
    //   build: () => UserBloc(
    //       authenticationRepository: authenticationRepository,
    //       userRepository: userRepository),
    //   act: (bloc) => {},
    //   expect: () => {},
    //   verify: (bloc) => {},
    // );

  });


}
