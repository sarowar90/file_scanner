import 'dart:io';
import 'package:path/path.dart' as path;

class FileHistoryItem {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String fileType;
  final DateTime scanDate;
  final DateTime lastModified;
  bool isFavorite;

  FileHistoryItem({required this.id, required this.filePath, required this.fileName, required this.fileSize, required this.fileType, required this.scanDate, required this.lastModified, this.isFavorite = false});

  // Check if file exists on disk
  Future<bool> fileExists() async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  // Get file size in human-readable format
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {'id': id, 'filePath': filePath, 'fileName': fileName, 'fileSize': fileSize, 'fileType': fileType, 'scanDate': scanDate.toIso8601String(), 'lastModified': lastModified.toIso8601String(), 'isFavorite': isFavorite};
  }

  // Create from JSON
  factory FileHistoryItem.fromJson(Map<String, dynamic> json) {
    return FileHistoryItem(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      fileType: json['fileType'] as String,
      scanDate: DateTime.parse(json['scanDate'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  // Create from file path
  static Future<FileHistoryItem> fromFile(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    final fileName = path.basename(filePath);
    final fileType = path.extension(filePath).replaceFirst('.', '').toUpperCase();

    // Generate unique ID from path and timestamp
    final id = '${filePath}_${stat.modified.millisecondsSinceEpoch}'.hashCode.toString();

    return FileHistoryItem(id: id, filePath: filePath, fileName: fileName, fileSize: stat.size, fileType: fileType.isEmpty ? 'UNKNOWN' : fileType, scanDate: DateTime.now(), lastModified: stat.modified);
  }

  // Copy with method for updating properties
  FileHistoryItem copyWith({String? id, String? filePath, String? fileName, int? fileSize, String? fileType, DateTime? scanDate, DateTime? lastModified, bool? isFavorite}) {
    return FileHistoryItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      scanDate: scanDate ?? this.scanDate,
      lastModified: lastModified ?? this.lastModified,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
