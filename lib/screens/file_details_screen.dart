import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/file_history_item.dart';
import '../services/file_history_service.dart';

class FileDetailsScreen extends StatefulWidget {
  final FileHistoryItem item;
  final FileHistoryService historyService;
  final VoidCallback onUpdate;

  const FileDetailsScreen({super.key, required this.item, required this.historyService, required this.onUpdate});

  @override
  State<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends State<FileDetailsScreen> {
  bool _fileExists = true;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    final exists = await widget.item.fileExists();
    setState(() {
      _fileExists = exists;
    });
  }

  Future<void> _toggleFavorite() async {
    await widget.historyService.toggleFavorite(widget.item.id);
    setState(() {});
    widget.onUpdate();
  }

  Future<void> _deleteFile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete from History'),
        content: Text('Remove "${widget.item.fileName}" from history?\n\nThis will not delete the actual file from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.historyService.removeFile(widget.item.id);
      if (success && mounted) {
        widget.onUpdate();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from history'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _openFile() async {
    if (!_fileExists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found on device'), backgroundColor: Colors.red));
      return;
    }

    // For now, just show the file path
    // In a real app, you would use a package like open_file to open the file
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Location'),
        content: SelectableText(widget.item.filePath),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('File Details'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(widget.item.isFavorite ? Icons.star : Icons.star_border), onPressed: _toggleFavorite),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteFile),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // File Preview Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500]),
              ),
              child: Column(
                children: [
                  if (_fileExists && widget.item.fileType.toUpperCase() == 'JPG' || widget.item.fileType.toUpperCase() == 'JPEG' || widget.item.fileType.toUpperCase() == 'PNG')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.item.filePath),
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFileIcon();
                        },
                      ),
                    )
                  else
                    _buildFileIcon(),
                  const SizedBox(height: 20),
                  Text(
                    widget.item.fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (!_fileExists) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('File not found', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailCard('File Information', [_buildDetailRow('File Name', widget.item.fileName), _buildDetailRow('File Type', widget.item.fileType), _buildDetailRow('File Size', widget.item.formattedSize)]),
                  const SizedBox(height: 16),
                  _buildDetailCard('Dates', [_buildDetailRow('Scanned', DateFormat('MMM dd, yyyy • HH:mm').format(widget.item.scanDate)), _buildDetailRow('Last Modified', DateFormat('MMM dd, yyyy • HH:mm').format(widget.item.lastModified))]),
                  const SizedBox(height: 16),
                  _buildDetailCard('Location', [_buildDetailRow('Path', widget.item.filePath, isPath: true)]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _fileExists
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _openFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new),
                      SizedBox(width: 8),
                      Text('View File Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFileIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.description, size: 60, color: Colors.white),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          isPath ? SelectableText(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)) : Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
