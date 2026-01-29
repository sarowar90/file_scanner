# File Scanner - Document History & Favorites

A modern Flutter application for scanning documents with comprehensive file history management and favorites functionality.

## Features

- 📸 **Document Scanning** - Capture documents using your device camera with automatic edge detection
- 📁 **File History** - Track all scanned documents with persistent storage
- ⭐ **Favorites** - Mark important files for quick access
- 🔍 **Search** - Find files quickly by name with real-time filtering
- 🗑️ **Delete** - Remove files from history with swipe gestures or confirmation dialogs
- 📊 **File Details** - View comprehensive metadata including size, dates, and type
- 🚫 **Duplicate Prevention** - Automatically prevents duplicate entries
- ⚠️ **Missing File Detection** - Visual indicators for files that no longer exist
- 🎨 **Premium UI** - Modern design with gradients, glassmorphism, and smooth animations

## Screenshots

### Scanner Screen
- Premium gradient background
- Real-time statistics (total scans, favorites)
- One-tap document scanning
- Quick access to history

### History Screen
- Search bar with real-time filtering
- Favorites filter toggle
- Sort options (date, name, size)
- Swipe-to-delete functionality
- Color-coded file type badges
- Missing file indicators

### File Details Screen
- Image preview for photos
- Comprehensive metadata display
- Favorite toggle
- File location with copy support
- Delete confirmation

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd file_scanner
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

- `cunning_document_scanner` - Document scanning with camera
- `shared_preferences` - Local data persistence
- `path_provider` - File system access
- `intl` - Date formatting
- `path` - Path manipulation

## Usage

### Scanning Documents

1. Launch the app
2. Tap "Start Scanning"
3. Grant camera permissions if prompted
4. Capture your document
5. Review and confirm
6. File is automatically saved and added to history

### Managing History

- **Search**: Use the search bar to find files by name
- **Filter**: Toggle "Favorites Only" to see starred files
- **Sort**: Choose from date, name, or size sorting
- **Delete**: Swipe left on a file or use the delete button in details
- **Favorite**: Tap the star icon to mark/unmark favorites

### Viewing Details

- Tap any file in history to view full details
- See file size, scan date, last modified date
- View image preview (for JPG/PNG files)
- Access full file path
- Open file location

## Architecture

### Data Layer
- **FileHistoryItem** - Data model with JSON serialization
- **StorageService** - Persistence using shared_preferences
- **FileHistoryService** - Business logic for file management

### UI Layer
- **ScannerScreen** - Main landing page with scanning functionality
- **HistoryScreen** - File list with search, filter, and sort
- **FileDetailsScreen** - Detailed file information display

## Technical Details

### Storage
Files are stored in the app's documents directory under `/scans/` with timestamp-based naming:
```
/data/user/0/com.example.file_scanner/app_flutter/scans/scan_1738131600000.jpg
```

History metadata is persisted in shared_preferences as JSON.

### Duplicate Prevention
Files are identified by their path. If the same file is scanned again:
- Existing entry is updated with new metadata
- Favorite status is preserved
- No duplicate entries are created

### File Validation
- Files are validated when viewing history
- Missing files show warning indicators
- Pull-to-refresh validates all files
- Graceful handling of missing files

## Future Enhancements

- [ ] Bulk operations (select multiple files)
- [ ] File sharing and export to PDF
- [ ] Cloud sync and backup
- [ ] Advanced filters (date range, file type)
- [ ] OCR text extraction
- [ ] Folders and tags for organization

## License

This project is licensed under the MIT License.

## Support

For issues, questions, or contributions, please open an issue on GitHub.
