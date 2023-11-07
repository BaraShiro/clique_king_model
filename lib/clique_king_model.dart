/// A library containing the model for the Clique King app.
library;


export 'src/repositories/hive_store.dart';
export 'src/repositories/user_repository.dart';
export 'src/repositories/authentication_repository.dart';
export 'src/repositories/clique_repository.dart';
export 'src/repositories/repository_error.dart';
export 'src/models/repositories.dart';
export 'src/models/helpers.dart';
export 'src/models/clique.dart';
export 'src/models/score.dart';
export 'src/models/user.dart';
export 'src/bloc/clique/clique_bloc.dart';
export 'src/bloc/cliques/cliques_bloc.dart';
export 'src/bloc/user/user_bloc.dart';

/// A user id corresponding to a Firebase Authentication User UID.
typedef UserId = String;
/// A v4 UUID clique id.
typedef CliqueId = String;

/// /// Key to users collection i database.
const String userCollection = "users";
/// Key to cliques collection i database.
const String cliqueCollection = "cliques";
/// Key to participants collection i database.
const String participantCollection = "participants";
/// Passwords must be at least this long.
const int minimumPasswordLength = 8;