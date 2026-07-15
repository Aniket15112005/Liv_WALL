import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper.dart';

class WallpaperService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('com.livewallpaper.app/wallpaper');

  List<WallpaperModel> _wallpapers = [];
  WallpaperModel? _activeWallpaper;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';

  List<WallpaperModel> get wallpapers => _wallpapers;
  WallpaperModel? get activeWallpaper => _activeWallpaper;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  final List<String> categories = [
    'All',
    'Particles',
    'Waves',
    'Geometric',
    'Galaxy',
    'Neon',
    'Nature',
  ];

  WallpaperService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _wallpapers = WallpaperModel.defaultWallpapers;
    await _loadFavorites();
    await _loadActiveWallpaper();
    notifyListeners();
  }

  List<WallpaperModel> get filteredWallpapers {
    if (_selectedCategory == 'All') return _wallpapers;
    return _wallpapers.where((w) {
      switch (_selectedCategory) {
        case 'Particles':
          return w.type == WallpaperType.particles;
        case 'Waves':
          return w.type == WallpaperType.waves;
        case 'Geometric':
          return w.type == WallpaperType.geometric;
        case 'Galaxy':
          return w.type == WallpaperType.galaxy;
        case 'Neon':
          return w.type == WallpaperType.neonPulse ||
              w.name.toLowerCase().contains('neon');
        case 'Nature':
          return w.type == WallpaperType.aurora;
        default:
          return true;
      }
    }).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> applyWallpaper(WallpaperModel wallpaper) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _channel.invokeMethod('applyWallpaper', {
        'wallpaperId': wallpaper.id,
        'wallpaperType': wallpaper.typeIndex,
        'colors': wallpaper.colors,
      });

      if (result == true) {
        _activeWallpaper = wallpaper;
        await _saveActiveWallpaper(wallpaper.id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to apply wallpaper. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'An error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkWallpaperServiceEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isWallpaperServiceEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openWallpaperPicker() async {
    try {
      await _channel.invokeMethod('openWallpaperPicker');
    } on PlatformException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  void toggleFavorite(WallpaperModel wallpaper) {
    wallpaper.isFavorite = !wallpaper.isFavorite;
    _saveFavorites();
    notifyListeners();
  }

  List<WallpaperModel> get favorites =>
      _wallpapers.where((w) => w.isFavorite).toList();

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds =
        _wallpapers.where((w) => w.isFavorite).map((w) => w.id).toList();
    await prefs.setStringList('favorites', favoriteIds);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorites') ?? [];
    for (var w in _wallpapers) {
      w.isFavorite = favoriteIds.contains(w.id);
    }
  }

  Future<void> _saveActiveWallpaper(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeWallpaper', id);
  }

  Future<void> _loadActiveWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString('activeWallpaper');
    if (activeId != null) {
      _activeWallpaper = _wallpapers.firstWhere(
        (w) => w.id == activeId,
        orElse: () => _wallpapers.first,
      );
    }
  }
}
