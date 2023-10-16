import 'package:meta/meta.dart';

@immutable
final class User {
  final String id; // TODO: probably should map to Firebase Authentication id.
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });
}
