import 'package:clique_king_model/clique_king_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

@immutable
class Clique extends Equatable {
  final CliqueId id;
  final String name;
  final UserId creatorId;

  Clique({required this.name, required this.creatorId})
      : id = Uuid().v4();

  Clique.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        creatorId = map['creatorId'];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'creatorId': creatorId
  };

  @override
  List<Object?> get props => [id, name, creatorId];
}
