import 'dart:io';
import '../models/file_history_item.dart';
import 'storage_service.dart';

class FileHistoryService {
  final StorageService _storageService = StorageService();
  List<FileHistoryItem> _historyItems = [];

  // Get all history items
  List<FileHistoryItem> get allItems => List.unmodifiable(_historyItems);

  // Initialize and load history
  Future<void> initialize() async {
    _historyItems = await _storageService.loadHistory();
  }

  // Add file to history (with duplicate prevention)
  Future<bool> addFile(String filePath) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final stat = await file.stat();

      // Check for duplicate (same path)
      final existingIndex = _historyItems.indexWhere((item) => item.filePath == filePath);

      if (existingIndex != -1) {
        // Update existing entry if file was modified
        final existing = _historyItems[existingIndex];
        if (existing.lastModified != stat.modified) {
          final updated = await FileHistoryItem.fromFile(filePath);
          updated.isFavorite = existing.isFavorite; // Preserve favorite status
          _historyItems[existingIndex] = updated;
        }
      } else {
        // Add new entry
        final newItem = await FileHistoryItem.fromFile(filePath);
        _historyItems.insert(0, newItem); // Add to beginning
      }

      return await _storageService.saveHistory(_historyItems);
    } catch (e) {
      print('Error adding file to history: $e');
      return false;
    }
  }

  // Remove file from history
  Future<bool> removeFile(String id) async {
    try {
      _historyItems.removeWhere((item) => item.id == id);
      return await _storageService.saveHistory(_historyItems);
    } catch (e) {
      print('Error removing file from history: $e');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String id) async {
    try {
      final index = _historyItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _historyItems[index].isFavorite = !_historyItems[index].isFavorite;
        return await _storageService.saveHistory(_historyItems);
      }
      return false;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Search files by name
  List<FileHistoryItem> searchByName(String query) {
    if (query.isEmpty) {
      return allItems;
    }

    final lowerQuery = query.toLowerCase();
    return _historyItems.where((item) {
      return item.fileName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get only favorites
  List<FileHistoryItem> getFavorites() {
    return _historyItems.where((item) => item.isFavorite).toList();
  }

  // Sort by date (newest first)
  List<FileHistoryItem> sortByDate({bool ascending = false}) {
    final sorted = List<FileHistoryItem>.from(_historyItems);
    sorted.sort((a, b) => ascending ? a.scanDate.compareTo(b.scanDate) : b.scanDate.compareTo(a.scanDate));
    return sorted;
  }

  // Sort by name
  List<FileHistoryItem> sortByName({bool ascending = true}) {
    final sorted = List<FileHistoryItem>.from(_historyItems);
    sorted.sort((a, b) => ascending ? a.fileName.compareTo(b.fileName) : b.fileName.compareTo(a.fileName));
    return sorted;
  }

  // Sort by size
  List<FileHistoryItem> sortBySize({bool ascending = false}) {
    final sorted = List<FileHistoryItem>.from(_historyItems);
    sorted.sort((a, b) => ascending ? a.fileSize.compareTo(b.fileSize) : b.fileSize.compareTo(a.fileSize));
    return sorted;
  }

  // Validate all files and return list of missing files
  Future<List<FileHistoryItem>> validateFiles() async {
    final missingFiles = <FileHistoryItem>[];

    for (final item in _historyItems) {
      if (!await item.fileExists()) {
        missingFiles.add(item);
      }
    }

    return missingFiles;
  }

  // Remove all missing files from history
  Future<bool> cleanupMissingFiles() async {
    try {
      final missingFiles = await validateFiles();

      for (final missing in missingFiles) {
        _historyItems.removeWhere((item) => item.id == missing.id);
      }

      if (missingFiles.isNotEmpty) {
        return await _storageService.saveHistory(_historyItems);
      }

      return true;
    } catch (e) {
      print('Error cleaning up missing files: $e');
      return false;
    }
  }

  // Clear all history
  Future<bool> clearAll() async {
    try {
      _historyItems.clear();
      return await _storageService.clearHistory();
    } catch (e) {
      print('Error clearing all history: $e');
      return false;
    }
  }
}
