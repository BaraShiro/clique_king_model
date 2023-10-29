import 'package:string_validator/string_validator.dart';

/// Sanitizes [userName] by removing control characters, trimming whitespace,
/// and replacing `<`, `>`, `&`, `'` and `"` with HTML entities,
/// in that order.
///
/// ```dart
/// sanitizeUserName(" ") == ""
/// sanitizeUserName("\n \n") == ""
/// sanitizeUserName(" & ") == "&amp;"
/// ```
String sanitizeUserName(String userName) {
  userName = stripLow(userName); // Remove control characters
  userName = trim(userName); // Trim whitespace
  userName = escape(userName); //  replace <, >, &, ' and "

  return userName;
}