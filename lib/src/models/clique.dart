import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

@immutable
class Clique extends Equatable {
  final String id;
  final String name;

  Clique({required this.name})
      : id = Uuid().v4();

  Clique.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };

  @override
  List<Object?> get props => [id, name];
}
