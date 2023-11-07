import 'dart:async';
import 'package:firedart/firedart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';
import 'package:clique_king_model/clique_king_model.dart';

/// A repository for handling and storage of [Clique]s.
@immutable
class CliqueRepository {
  final Firestore store;

  /// Public constructor.
  CliqueRepository({required this.store});

  /// Creates a new [Clique] with a [name] and a [creatorId].
  ///
  /// Returns either the newly created [Clique], or a [FailedToCreateClique] error.
  Future<Either<RepositoryError, Clique>> createClique({required String name, required UserId creatorId}) async {
    Clique clique = Clique(name: name, creatorId: creatorId);
    Document cliqueDocument;
    try {
      cliqueDocument = await store
          .collection(cliqueCollection)
          .document(clique.id)
          .create(clique.toMap());
    } catch (e) {
      return Either.left(FailedToCreateClique(errorObject: e));
    }
    return Either.right(Clique.fromMap(cliqueDocument.map));
  }

  /// Reads all [Clique]s as a [Stream].
  ///
  /// Returns either a [Stream] containing a [List] of [Clique]s,
  /// or a a [FailedToStreamCliques] error.
  Either<RepositoryError, Stream<List<Clique>>> readAllCliques() {
    Stream<List<Document>> cliqueDocumentStream;
    try {
      cliqueDocumentStream = store
          .collection(cliqueCollection)
          .stream;
    } catch (e) {
      return Either.left(FailedToStreamCliques(errorObject: e));
    }

    Stream<List<Clique>> cliqueStream = cliqueDocumentStream.map(
            (cliqueDocuments) => cliqueDocuments.map(
                (cliqueDocument) => Clique.fromMap(cliqueDocument.map)
        ).toList()
    );

    return Either.right(cliqueStream);
  }

  /// Reads all [Score]s from a [Clique] as as [Stream].
  ///
  /// Returns either a [Stream] containing a [List] of [Score]s,
  /// or a [FailedToStreamScores] error.
  Either<RepositoryError, Stream<List<Score>>> readScoresFromClique({required CliqueId cliqueId}) {
    Stream<List<Document>> scoreDocumentStream;
    try {
      scoreDocumentStream = store
          .collection(cliqueCollection)
          .document(cliqueId)
          .collection(participantCollection)
          .stream;
    } catch (e) {
      return Either.left(FailedToStreamScores(errorObject: e));
    }

    Stream<List<Score>> scoreStream = scoreDocumentStream.map(
            (scoreDocuments) => scoreDocuments.map(
                (scoreDocument) => Score.fromMap(scoreDocument.map)
        ).toList()
    );

    return Either.right(scoreStream);
  }

  /// Adds a new [User] to a [Clique].
  ///
  /// Returns a [FailedToAddUserToClique] error if it fails, otherwise nothing.
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
      return Option.of(FailedToAddUserToClique(errorObject: e));
    }

    return Option.none();
  }

  /// Removes a existing [User] from a [Clique].
  ///
  /// Returns a [FailedToRemoveUserFromClique] error if it fails, otherwise nothing.
  Future<Option<RepositoryError>> removeUser({required CliqueId cliqueId, required UserId userId}) async {
    try {
      await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .collection(participantCollection)
          .document(userId)
          .delete();
    } catch (e) {
      return Option.of(FailedToRemoveUserFromClique(errorObject: e));
    }

    return Option.none();
  }

  /// Removes a [Clique] from the repository.
  ///
  /// Returns a [FailedToDeleteClique] error if it fails, otherwise nothing.
  ///
  /// Does currently *NOT* delete nested collection of user scores!
  Future<Option<RepositoryError>> deleteClique({required CliqueId cliqueId}) async {
    // TODO: Recursively remove all score documents?
    try {
      await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .delete();
    } catch (e) {
      return Option.of(FailedToDeleteClique(errorObject: e));
    }

    return Option.none();
  }

  /// Retrieves a [Clique] from the repository.
  ///
  /// Returns either the requested [Clique],
  /// or a [FailedToReadClique] error if it fails.
  Future<Either<RepositoryError, Clique>> getClique({required CliqueId cliqueId}) async {
    Document document;
    try {
      document = await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .get();
    } catch(e) {
      return Either.left(FailedToReadClique(errorObject: e));
    }

    return Either.right(Clique.fromMap(document.map));
  }

  /// Retrieves a [Score] for a specific [User] from the repository.
  ///
  /// Returns either the [Score] for the requested [User],
  /// or a [FailedToReadScore] error if it fails.
  Future<Either<RepositoryError, Score>> getScore({required CliqueId cliqueId, required UserId userId}) async {
    Document document;
    try {
      document = await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .collection(participantCollection)
          .document(userId)
          .get();
    } catch(e) {
      return Either.left(FailedToReadScore(errorObject: e));
    }

    return Either.right(Score.fromMap(document.map));
  }

  /// Increases the value of a certain [Score] by an amount equal to [scoreIncrease].
  ///
  /// Returns a [FailedToIncreaseScore] error if it fails, otherwise nothing.
  Future<Option<RepositoryError>> increaseScore({required CliqueId cliqueId, required Score score, required int scoreIncrease}) async {
    Score newScore = score.increaseScore(increase: scoreIncrease);
    try {
      await store
          .collection(cliqueCollection)
          .document(cliqueId)
          .collection(participantCollection)
          .document(score.userId)
          .update(newScore.toMap());
    } catch(e) {
      return Option.of(FailedToIncreaseScore(errorObject: e));
    }

    return Option.none();
  }
}
