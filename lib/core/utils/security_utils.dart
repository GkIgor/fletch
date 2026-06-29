import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  static String generateDynamicHash(String rawJson) {
    final String user = Platform.environment['USER'] ?? 'default_user';
    final String sizeSalt = (rawJson.length % 997).toString();
    final String host = Platform.localHostname;
    final String dynamicSalt = "$user@$host#$sizeSalt";

    final bytes = utf8.encode(rawJson + dynamicSalt);
    return sha256.convert(bytes).toString();
  }

  static String generateSHA256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
