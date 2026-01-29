import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/file_history_service.dart';
import 'history_screen.dart';

class ScannerScreen extends StatefulWidget {
  final FileHistoryService historyService;

  const ScannerScreen({super.key, required this.historyService});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanning = false;
  String? _lastScannedFile;

  Future<void> _scanDocument() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Launch document scanner
      List<String> pictures = await CunningDocumentScanner.getPictures() ?? [];

      if (pictures.isNotEmpty && mounted) {
        // Get app directory for saving
        final directory = await getApplicationDocumentsDirectory();
        final scansDir = Directory('${directory.path}/scans');

        // Create scans directory if it doesn't exist
        if (!await scansDir.exists()) {
          await scansDir.create(recursive: true);
        }

        // Copy scanned file to app directory
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'scan_$timestamp.jpg';
        final savedPath = '${scansDir.path}/$fileName';

        // Copy the first scanned image
        await File(pictures[0]).copy(savedPath);

        // Add to history
        final success = await widget.historyService.addFile(savedPath);

        if (success && mounted) {
          setState(() {
            _lastScannedFile = fileName;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document scanned: $fileName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View History',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(historyService: widget.historyService)));
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error scanning document: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900, Colors.black]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Document Scanner',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(historyService: widget.historyService)));
                      },
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scanner Icon
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Icon(Icons.document_scanner, size: 100, color: Colors.white.withOpacity(0.9)),
                      ),

                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        'Scan Your Documents',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      Text('Capture and save documents with ease', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),

                      const SizedBox(height: 60),

                      // Scan Button
                      ElevatedButton(
                        onPressed: _isScanning ? null : _scanDocument,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                        ),
                        child: _isScanning
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, size: 28),
                                  SizedBox(width: 12),
                                  Text('Start Scanning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),

                      if (_lastScannedFile != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                              const SizedBox(width: 8),
                              Text('Last scan: $_lastScannedFile', style: const TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Stats Section
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Total Scans', widget.historyService.allItems.length.toString(), Icons.description),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                    _buildStat('Favorites', widget.historyService.getFavorites().length.toString(), Icons.star),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
      ],
    );
  }
}
