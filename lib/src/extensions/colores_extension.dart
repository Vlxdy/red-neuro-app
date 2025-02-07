import 'dart:ui';

extension HexColor on Color {
  static Color fromHex(String? hexString) {
    final buffer = StringBuffer();
    if (hexString == null) return const Color(0xFF000000);
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16)}';
  }
}
