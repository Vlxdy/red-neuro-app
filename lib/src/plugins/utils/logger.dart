import 'dart:developer' as developer;

class Logger {
  static sesion(String message) => developer.log('\x1B[35m$message\x1B[0m');
  static info(String message) => developer.log('\x1B[34m$message\x1B[0m');
  static success(String message) => developer.log('\x1B[32m$message\x1B[0m');
  static warning(String message) => developer.log('\x1B[33m$message\x1B[0m');
  static error(String message) => developer.log('\x1B[31m$message\x1B[0m');
  static event(String message) => developer.log('\x1B[36m$message\x1B[0m');
}
