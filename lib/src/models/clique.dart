import 'package:meta/meta.dart';

typedef UserId = String;
typedef ParticipantScore = int;

@immutable
class Clique {
  final String id; // TODO: generate with uuid?
  final String name; // creator selects name of clique


  // TODO: Reflect over participantScores
  // The user with the highest score is the Clique King

  Clique({
    required this.id,
    required this.name,
  });
}
