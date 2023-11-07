import 'package:clique_king_model/clique_king_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// A clique with a unique [id], [name], and [creatorId].
@immutable
class Clique extends Equatable {
  final CliqueId id;
  final String name;
  final UserId creatorId;

  /// Public constructor.
  /// Automatically assigns [id] a random v4 UUID.
  Clique({required this.name, required this.creatorId})
      : id = Uuid().v4();

  /// Named constructor for reconstructing a [Clique] from a map.
  Clique.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        creatorId = map['creatorId'];

  /// Serializes a [Clique] into a map.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'creatorId': creatorId
  };

  @override
  List<Object?> get props => [id, name, creatorId];
}
