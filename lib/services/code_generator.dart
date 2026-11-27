import 'dart:math';

import '../config/app_config.dart';

/// Generates short, student-friendly test codes.
///
/// The alphabet deliberately excludes look-alike characters
/// (0/O, 1/I/L) so a code read out loud or copied from a board is hard
/// to mistype. TestService checks the generated code against Firestore
/// and retries on the (very unlikely) collision, which is what makes
/// the code effectively unique.
class CodeGenerator {
  CodeGenerator._();

  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String generate({int length = AppConfig.testCodeLength}) {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }
}
