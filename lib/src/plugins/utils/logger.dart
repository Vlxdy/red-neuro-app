import 'dart:developer' as developer;

class Logger {
  static void sesion(String message) =>
      developer.log('\x1B[35m$message\x1B[0m');
  static void info(String message) => developer.log('\x1B[34m$message\x1B[0m');
  static void success(String message) =>
      developer.log('\x1B[32m$message\x1B[0m');
  static void warning(String message) =>
      developer.log('\x1B[33m$message\x1B[0m');
  static void error(String message) => developer.log('\x1B[31m$message\x1B[0m');
  static void event(String message) => developer.log('\x1B[36m$message\x1B[0m');
}
