import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

import '../models/history_entry.dart';
import '../models/saved_wallpaper.dart';

enum WallpaperQuality { dataSaver, balanced, best }

/// Owns the full lifecycle of user-imported video wallpapers: importing,
/// trimming/compressing, persisting the library, applying/removing the
/// live wallpaper, and keeping an apply history.
class VideoWallpaperService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('com.livewallpaper.app/wallpaper');

  static const _kLibraryKey = 'saved_wallpapers_v1';
  static const _kHistoryKey = 'wallpaper_history_v1';
  static const _kActiveIdKey = 'active_wallpaper_id_v1';
  static const _maxHistoryEntries = 50;

  final _uuid = const Uuid();

  List<SavedWallpaper> _wallpapers = [];
  List<HistoryEntry> _history = [];
  String? _activeWallpaperId;

  bool _isLoading = false;
  bool _isProcessing = false;
  double _processingProgress = 0;
  String? _errorMessage;

  List<SavedWallpaper> get wallpapers => List.unmodifiable(_wallpapers);
  List<HistoryEntry> get history => List.unmodifiable(_history);
  String? get activeWallpaperId => _activeWallpaperId;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  double get processingProgress => _processingProgress;
  String? get errorMessage => _errorMessage;

  SavedWallpaper? get activeWallpaper => _activeWallpaperId == null
      ? null
      : _wallpapers.where((w) => w.id == _activeWallpaperId).firstOrNull;

  VideoWallpaperService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _wallpapers = _decodeList(prefs.getString(_kLibraryKey))
        .map(SavedWallpaper.fromJson)
        .toList();
    _history = _decodeList(prefs.getString(_kHistoryKey))
        .map(HistoryEntry.fromJson)
        .toList();
    _activeWallpaperId = prefs.getString(_kActiveIdKey);

    // Reconcile with the system: if the user changed the home-screen
    // wallpaper to something else outside the app, drop our local
    // "active" flag so the UI doesn't lie about what's really applied.
    final stillOurs = await isOurWallpaperActive();
    if (!stillOurs) {
      _activeWallpaperId = null;
      await prefs.remove(_kActiveIdKey);
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLibraryKey,
      jsonEncode(_wallpapers.map((w) => w.toJson()).toList()),
    );
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(_history.map((h) => h.toJson()).toList()),
    );
  }

  /// Trims [sourcePath] to [start]..[end] (seconds), compresses it for the
  /// chosen [quality] and smoothness, and stores the result permanently in
  /// the app's own storage. Screen-ratio fitting is intentionally NOT baked
  /// into the file — the native wallpaper engine crops/scales the video to
  /// the device's screen at render time, which keeps it sharp on every
  /// device instead of hard-coding one aspect ratio. The grid/preview UI
  /// shows a live paused video frame instead of a separately generated
  /// thumbnail image, so no extra thumbnail-generation plugin is needed.
  Future<SavedWallpaper?> processAndSave({
    required String sourcePath,
    required String title,
    required double start,
    required double end,
    required WallpaperQuality quality,
  }) async {
    _isProcessing = true;
    _processingProgress = 0;
    _errorMessage = null;
    notifyListeners();

    final progressSub = VideoCompress.compressProgress$.subscribe((p) {
      _processingProgress = p / 100;
      notifyListeners();
    });

    try {
      final durationSeconds = (end - start).clamp(1, 60).round();

      final info = await VideoCompress.compressVideo(
        sourcePath,
        quality: _mapQuality(quality),
        deleteOrigin: false,
        includeAudio: false,
        frameRate: 30,
        startTime: start.round(),
        duration: durationSeconds,
      );

      if (info == null || info.path == null) {
        _errorMessage = 'Could not process that video. Try a different file.';
        return null;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final wallpapersDir = Directory('${docsDir.path}/wallpapers');
      if (!await wallpapersDir.exists()) {
        await wallpapersDir.create(recursive: true);
      }

      final id = _uuid.v4();
      final destVideoPath = '${wallpapersDir.path}/$id.mp4';
      await File(info.path!).copy(destVideoPath);

      final sizeBytes = await File(destVideoPath).length();

      final wallpaper = SavedWallpaper(
        id: id,
        title: title.trim().isEmpty ? 'My Wallpaper' : title.trim(),
        videoPath: destVideoPath,
        // No separate thumbnail file — the UI renders a paused frame
        // straight from videoPath instead.
        thumbnailPath: '',
        durationMs: durationSeconds * 1000,
        sizeBytes: sizeBytes,
        createdAt: DateTime.now(),
      );

      _wallpapers = [wallpaper, ..._wallpapers];
      await _persistLibrary();
      return wallpaper;
    } catch (e) {
      _errorMessage = 'Something went wrong while processing the video: $e';
      return null;
    } finally {
      progressSub.unsubscribe();
      await VideoCompress.deleteAllCache();
      _isProcessing = false;
      _processingProgress = 0;
      notifyListeners();
    }
  }

  VideoQuality _mapQuality(WallpaperQuality q) {
    switch (q) {
      case WallpaperQuality.dataSaver:
        return VideoQuality.LowQuality;
      case WallpaperQuality.balanced:
        return VideoQuality.Res1280x720Quality;
      case WallpaperQuality.best:
        // Res1920x1080Quality forces a resize step that fails on many
        // Android hardware encoders for portrait clips (this is what was
        // causing "Could not process that video"). HighestQuality instead
        // keeps the video's ORIGINAL resolution untouched and only caps
        // the bitrate, which avoids the resize step entirely and is far
        // more reliable across devices, including the GT Neo 3.
        return VideoQuality.HighestQuality;
    }
  }

  /// Sends the video to Android's system "set live wallpaper" flow. Android
  /// requires the user to confirm this step themselves (via the system
  /// picker) — no app can silently set a live wallpaper, which is a
  /// platform security restriction, not a limitation of this app.
  Future<bool> applyWallpaper(SavedWallpaper wallpaper) async {
    _errorMessage = null;
    try {
      final result = await _channel.invokeMethod<bool>('setLiveWallpaper', {
        'path': wallpaper.videoPath,
      });

      if (result == true) {
        _activeWallpaperId = wallpaper.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kActiveIdKey, wallpaper.id);

        _history = [
          HistoryEntry(
            id: _uuid.v4(),
            wallpaperId: wallpaper.id,
            title: wallpaper.title,
            videoPath: wallpaper.videoPath,
            appliedAt: DateTime.now(),
          ),
          ..._history,
        ];
        if (_history.length > _maxHistoryEntries) {
          _history = _history.sublist(0, _maxHistoryEntries);
        }
        await _persistHistory();

        notifyListeners();
        return true;
      }
      _errorMessage = 'The system did not confirm the wallpaper change.';
      notifyListeners();
      return false;
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Failed to open the wallpaper chooser.';
      notifyListeners();
      return false;
    }
  }

  /// Removes the live wallpaper entirely, reverting the home screen to the
  /// system default. Does not delete anything from the library.
  Future<bool> removeActiveWallpaper() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('clearLiveWallpaper');
      if (result == true) {
        _activeWallpaperId = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kActiveIdKey);
        notifyListeners();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Failed to remove the live wallpaper.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> isOurWallpaperActive() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isLiveWallpaperActive');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Deletes a saved wallpaper permanently: its video file, its thumbnail,
  /// and its library entry. If it's currently active, also clears the live
  /// wallpaper so the app never points at a file that no longer exists.
  Future<void> deleteWallpaper(String id) async {
    final wallpaper = _wallpapers.where((w) => w.id == id).firstOrNull;
    if (wallpaper == null) return;

    if (_activeWallpaperId == id) {
      await removeActiveWallpaper();
    }

    for (final path in [wallpaper.videoPath, wallpaper.thumbnailPath]) {
      if (path.isEmpty) continue;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _wallpapers = _wallpapers.where((w) => w.id != id).toList();
    await _persistLibrary();
    notifyListeners();
  }

  Future<void> renameWallpaper(String id, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    _wallpapers = _wallpapers.map((w) {
      if (w.id != id) return w;
      return SavedWallpaper(
        id: w.id,
        title: trimmed,
        videoPath: w.videoPath,
        thumbnailPath: w.thumbnailPath,
        durationMs: w.durationMs,
        sizeBytes: w.sizeBytes,
        createdAt: w.createdAt,
      );
    }).toList();
    await _persistLibrary();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    await _persistHistory();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
