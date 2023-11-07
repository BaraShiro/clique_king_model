import 'package:clique_king_model/clique_king_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// The score of a certain [User] in a [Clique].
@immutable
class Score extends Equatable {
  final String userId;
  final String userName;
  final int score;

  /// Public constructor.
  Score({
    required this.userId,
    required this.userName,
    required this.score,
  });

  /// Named constructor for creating an initial [Score] for a [User].
  Score.fromUser(User user):
    userId = user.id,
    userName = user.name,
    score = 0;

  /// Named constructor for reconstructing a [Score] from a map.
  Score.fromMap(Map<String, dynamic> map):
    userId = map['userId'],
    userName = map['userName'],
    score = map['score'];

  /// Serializes a [Score] into a map.
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'score': score,
  };

  /// Returns a [Score] with an increased [score].
  Score increaseScore({required int increase}) {
    return Score(userId: userId, userName: userName, score: score + increase);
  }

  @override
  List<Object?> get props => [userId, userName, score];
}