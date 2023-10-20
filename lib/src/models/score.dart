import 'package:clique_king_model/src/models/user.dart';
import 'package:meta/meta.dart';

@immutable
class Score {
  final String userId;
  final String userName;
  final int score;

  Score({
    required this.userId,
    required this.userName,
    required this.score,
  });

  Score.fromUser(User user):
    userId = user.id,
    userName = user.name,
    score = 0;

  Score.fromMap(Map<String, dynamic> map):
    userId = map['userId'],
    userName = map['userName'],
    score = map['score'];

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'score': score,
  };
}