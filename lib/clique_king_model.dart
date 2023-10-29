/// Nifty dartdoc description
///
/// More dartdocs go here.
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

typedef UserId = String;
typedef CliqueId = String;

const String userCollection = "users";
const String cliqueCollection = "cliques";
const String participantCollection = "participants";