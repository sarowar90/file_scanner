import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_history_item.dart';

class StorageService {
  static const String _historyKey = 'file_history';

  // Save history list to storage
  Future<bool> saveHistory(List<FileHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(_historyKey, jsonString);
    } catch (e) {
      print('Error saving history: $e');
      return false;
    }
  }

  // Load history list from storage
  Future<List<FileHistoryItem>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => FileHistoryItem.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  // Clear all history
  Future<bool> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
      return false;
    }
  }
}
