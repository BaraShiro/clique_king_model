import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

@immutable
final class User extends Equatable{
  final String id; // TODO: probably should map to Firebase Authentication id.
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, email];
}
