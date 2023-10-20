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

}