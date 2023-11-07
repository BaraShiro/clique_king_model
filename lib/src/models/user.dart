import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:firedart/auth/user_gateway.dart' as auth;

/// A representation of a user with a unique [id], [name], and [email].
@immutable
final class User extends Equatable {
  final String id;
  final String name;
  final String email;

  /// Public constructor.
  User({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Named constructor for handling potential null values passed from a
  /// Firebase Auth user.
  User.fromAuthUser(auth.User user):
    id = user.id,
    name = user.displayName ?? "",
    email = user.email ?? "";

  /// Named constructor for reconstructing a [User] from a map.
  User.fromMap(Map<String, dynamic> map):
    id = map['id'],
    name = map['name'],
    email = map['email'];

  /// Serializes a [User] into a map.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
  };

  /// Returns a [User] with an updated name.
  User updateName(String newName) {
    return User(id: id, name: newName, email: email);
  }

  @override
  List<Object?> get props => [id, name, email];
}
