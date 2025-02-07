import 'dart:convert';

class Encode {
  static toBase64(String value) =>
      base64.encode(utf8.encode(Uri.encodeFull(value)));

  static decodeBase64(String value) =>
      Uri.decodeFull(utf8.decode(base64.decode(value)));
}
