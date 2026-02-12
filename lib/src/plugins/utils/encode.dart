import 'dart:convert';

class Encode {
  static String toBase64(String value) =>
      base64.encode(utf8.encode(Uri.encodeFull(value)));

  static String decodeBase64(String value) =>
      Uri.decodeFull(utf8.decode(base64.decode(value)));
}
