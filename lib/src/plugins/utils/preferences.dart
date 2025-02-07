import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();
  static final instance = PreferencesService._();

  Future<String> getString(String key) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.getString(key) ?? '';
  }

  Future<void> setString(String key, String value) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    instance.setString(key, value);
  }

  Future<int> getInt(String key) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.getInt(key) ?? 0;
  }

  Future<void> setInt(String key, int value) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    instance.setInt(key, value);
  }

  Future<bool> getBool(String key) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.getBool(key) ?? true;
  }

  Future<void> setBool(String key, bool value) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    instance.setBool(key, value);
  }

  Future<bool> remove(String key) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return await instance.remove(key);
  }

  Future<void> setStringSecure(String key, String value) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: key, value: value);
  }

  Future<String> getStringSecure(String key) async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: key) ?? '';
  }

  Future<List<String>> getStringList(String key) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.getStringList(key) ?? <String>[];
  }

  Future<void> setStringList(String key, List<String> values) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    instance.setStringList(key, values);
  }
}
