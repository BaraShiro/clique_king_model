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
      document = await store
          .collection(cliqueCollection)
          .document(clique.id)
          .create(clique.toMap());
    } catch (e) {
      return Either.left(RepositoryError(errorObject: e));
    }
    return Either.right(Clique.fromMap(document.map));
  }

  Either<RepositoryError, Stream<List<Clique>>> readAllCliques() {
    Stream<List<Document>> cliqueDocumentStream;
    try {
      cliqueDocumentStream = store.collection("cliques").stream;
    } catch (e) {
      return Either.left(RepositoryError(errorObject: e));
    }

    Stream<List<Clique>> cliqueStream = cliqueDocumentStream.map(
            (cliqueDocuments) => cliqueDocuments.map(
                (cliqueDocument) => Clique.fromMap(cliqueDocument.map)
        ).toList()
    );

    return Either.right(cliqueStream);
  }

  Either<RepositoryError, Stream<List<Score>>> readScoresFromClique({required CliqueId cliqueId}) {
    Stream<List<Document>> scoreDocumentStream;
    try {
      scoreDocumentStream = store
          .collection(cliqueCollection)
          .document(cliqueId)
          .collection(participantCollection).stream;
    } catch (e) {
      return Either.left(RepositoryError(errorObject: e));
    }

    Stream<List<Score>> scoreStream = scoreDocumentStream.map(
            (scoreDocuments) => scoreDocuments.map(
                (scoreDocument) => Score.fromMap(scoreDocument.map)
        ).toList()
    );

    return Either.right(scoreStream);
  }

  Future<Option<RepositoryError>> addUser({required CliqueId cliqueId, required User user}) async {
    Score score = Score.fromUser(user);
    try {
      await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .collection(participantCollection)
          .document(score.userId)
          .create(score.toMap());
    } catch (e) {
      return Option.of(RepositoryError(errorObject: e));
    }

    return Option.none();
  }

  Future<Option<RepositoryError>> removeUser({required CliqueId cliqueId, required UserId userId}) async {
    try {
      await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .collection(participantCollection)
          .document(userId)
          .delete();
    } catch (e) {
      return Option.of(RepositoryError(errorObject: e));
    }

    return Option.none();
  }

  Future<Option<RepositoryError>> deleteClique({required CliqueId cliqueId}) async {
    try {
      await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .delete();
    } catch (e) {
      return Option.of(RepositoryError(errorObject: e));
    }

    return Option.none();
  }

}
