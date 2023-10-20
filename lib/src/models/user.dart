import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:firedart/auth/user_gateway.dart' as auth;

@immutable
final class User extends Equatable{
  final String id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  User.fromAuthUser(auth.User user):
    id = user.id,
    name = user.displayName ?? "",
    email = user.email ?? "";

  User.fromMap(Map<String, dynamic> map):
    id = map['id'],
    name = map['name'],
    email = map['email'];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
  };

  User updateName(String newName) {
    return User(id: id, name: newName, email: email);
  }

  @override
  List<Object?> get props => [id, name, email];
}
