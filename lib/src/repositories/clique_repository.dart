import 'dart:async';
import 'package:firedart/firedart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';
import 'package:clique_king_model/clique_king_model.dart';

@immutable
class CliqueRepository {
  final Firestore store;

  CliqueRepository({required this.store});

  Future<Either<RepositoryError, Clique>> createClique({required String name}) async {
    Clique clique = Clique(name: name);
    Document document;
    try {
      document = await store.collection(cliqueCollection).document(clique.id).create(clique.toMap());
    } catch (e) {
      return Either.left(RepositoryError(errorObject: e));
    }
    return Either.right(Clique.fromMap(document.map));
  }

  Stream<List<Clique>> readAllCliques() async* {
    Stream<List<Document>> cliquesStream = store.collection("cliques").stream;

    await for (List<Document> cliquesEvent in cliquesStream) {
      List<Clique> allCliques = cliquesEvent.map(
              (cliqueDocument) => Clique.fromMap(cliqueDocument.map)
      ).toList();
      yield allCliques;
    }
  }

  Stream<List<Score>> readScoresFromClique({required CliqueId cliqueId}) async* {
    Stream<List<Document>> scoresStream = store.collection(cliqueCollection).document(cliqueId).collection(participantCollection).stream;

    await for (List<Document> scoresEvent in scoresStream) {
      List<Score> allScores = scoresEvent.map(
              (scoreDocument) => Score.fromMap(scoreDocument.map)
      ).toList();
      yield allScores;
    }
  }

  Future<Option<RepositoryError>> addUser({required CliqueId cliqueId, required User user}) async {
    Score score = Score.fromUser(user);
    try {
      await store.collection(cliqueCollection).document(cliqueId).collection(participantCollection).document(score.userId).create(score.toMap());
    } catch (e) {
      return Option.of(RepositoryError(errorObject: e));
    }

    return Option.none();
  }

  void removeUser({required CliqueId cliqueId, required UserId userId}) async {
    throw UnimplementedError();
  }

  void deleteClique({required CliqueId cliqueId}) async {
    throw UnimplementedError();
  }

}
