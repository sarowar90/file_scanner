import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/file_history_item.dart';
import '../services/file_history_service.dart';
import 'file_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  final FileHistoryService historyService;

  const HistoryScreen({super.key, required this.historyService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  String _sortBy = 'date'; // date, name, size
  List<FileHistoryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredItems();
  }

  void _updateFilteredItems() {
    List<FileHistoryItem> items;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      items = widget.historyService.searchByName(_searchQuery);
    } else {
      // Create a mutable copy of the list
      items = List<FileHistoryItem>.from(widget.historyService.allItems);
    }

    // Apply favorites filter
    if (_showFavoritesOnly) {
      items = items.where((item) => item.isFavorite).toList();
    }

    // Apply sorting (now safe because items is mutable)
    switch (_sortBy) {
      case 'name':
        items.sort((a, b) => a.fileName.compareTo(b.fileName));
        break;
      case 'size':
        items.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case 'date':
      default:
        items.sort((a, b) => b.scanDate.compareTo(a.scanDate));
        break;
    }

    setState(() {
      _filteredItems = items;
    });
  }

  Future<void> _deleteFile(FileHistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete from History'),
        content: Text('Remove "${item.fileName}" from history?'),
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
      final success = await widget.historyService.removeFile(item.id);
      if (success && mounted) {
        _updateFilteredItems();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from history'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _toggleFavorite(FileHistoryItem item) async {
    await widget.historyService.toggleFavorite(item.id);
    _updateFilteredItems();
  }

  Future<void> _refreshFiles() async {
    await widget.historyService.initialize();
    _updateFilteredItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('File History'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _updateFilteredItems();
            },
            itemBuilder: (context) => [const PopupMenuItem(value: 'date', child: Text('Sort by Date')), const PopupMenuItem(value: 'name', child: Text('Sort by Name')), const PopupMenuItem(value: 'size', child: Text('Sort by Size'))],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.deepPurple.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _updateFilteredItems();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                              _updateFilteredItems();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                // Favorites Filter
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Favorites Only'),
                      selected: _showFavoritesOnly,
                      onSelected: (value) {
                        setState(() {
                          _showFavoritesOnly = value;
                        });
                        _updateFilteredItems();
                      },
                      selectedColor: Colors.amber.shade300,
                      checkmarkColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredItems.length} files',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // File List
          Expanded(
            child: _filteredItems.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshFiles,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return _buildFileItem(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_showFavoritesOnly ? Icons.star_border : Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _showFavoritesOnly
                ? 'No favorites yet'
                : _searchQuery.isNotEmpty
                ? 'No files found'
                : 'No scanned files',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _showFavoritesOnly
                ? 'Mark files as favorites to see them here'
                : _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Start scanning documents to build your history',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileHistoryItem item) {
    return FutureBuilder<bool>(
      future: item.fileExists(),
      builder: (context, snapshot) {
        final fileExists = snapshot.data ?? true;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Dismissible(
            key: Key(item.id),
            background: Container(
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _deleteFile(item),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: _getFileTypeColor(item.fileType), borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    item.fileType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.fileName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!fileExists)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${item.formattedSize} • ${_formatDate(item.scanDate)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (!fileExists)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'File not found',
                        style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(item.isFavorite ? Icons.star : Icons.star_border, color: item.isFavorite ? Colors.amber : Colors.grey),
                onPressed: () => _toggleFavorite(item),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FileDetailsScreen(item: item, historyService: widget.historyService, onUpdate: _updateFilteredItems),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color _getFileTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Colors.red.shade400;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Colors.blue.shade400;
      case 'DOC':
      case 'DOCX':
        return Colors.indigo.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
