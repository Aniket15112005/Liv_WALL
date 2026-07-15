enum WallpaperType {
  particles,
  waves,
  geometric,
  galaxy,
  neonPulse,
  matrixRain,
  aurora,
  fluidColors,
}

class WallpaperModel {
  final String id;
  final String name;
  final String description;
  final WallpaperType type;
  final List<int> colors; // color hex values
  final String previewEmoji;
  final String thumbnailAsset;
  bool isFavorite;

  WallpaperModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.colors,
    required this.previewEmoji,
    required this.thumbnailAsset,
    this.isFavorite = false,
  });

  int get typeIndex => type.index;

  static List<WallpaperModel> get defaultWallpapers => [
        WallpaperModel(
          id: 'particles_blue',
          name: 'Blue Particles',
          description: 'Shimmering blue particles floating in deep space',
          type: WallpaperType.particles,
          colors: [0xFF0D47A1, 0xFF1565C0, 0xFF42A5F5],
          previewEmoji: '✨',
          thumbnailAsset: 'particles_blue',
        ),
        WallpaperModel(
          id: 'particles_purple',
          name: 'Purple Galaxy',
          description: 'Vibrant purple particles swirling like a nebula',
          type: WallpaperType.particles,
          colors: [0xFF4A148C, 0xFF7B1FA2, 0xFFCE93D8],
          previewEmoji: '🔮',
          thumbnailAsset: 'particles_purple',
        ),
        WallpaperModel(
          id: 'waves_ocean',
          name: 'Ocean Waves',
          description: 'Smooth, calming waves of deep ocean blue',
          type: WallpaperType.waves,
          colors: [0xFF006064, 0xFF00838F, 0xFF26C6DA],
          previewEmoji: '🌊',
          thumbnailAsset: 'waves_ocean',
        ),
        WallpaperModel(
          id: 'waves_sunset',
          name: 'Sunset Waves',
          description: 'Warm, glowing waves of orange and red',
          type: WallpaperType.waves,
          colors: [0xFFBF360C, 0xFFE64A19, 0xFFFF8A65],
          previewEmoji: '🌅',
          thumbnailAsset: 'waves_sunset',
        ),
        WallpaperModel(
          id: 'geometric_dark',
          name: 'Dark Geometry',
          description: 'Rotating geometric shapes on dark background',
          type: WallpaperType.geometric,
          colors: [0xFF1A237E, 0xFF283593, 0xFF3949AB],
          previewEmoji: '🔷',
          thumbnailAsset: 'geometric_dark',
        ),
        WallpaperModel(
          id: 'geometric_neon',
          name: 'Neon Geometry',
          description: 'Glowing neon geometric patterns',
          type: WallpaperType.geometric,
          colors: [0xFF00E676, 0xFF1DE9B6, 0xFF00BCD4],
          previewEmoji: '💠',
          thumbnailAsset: 'geometric_neon',
        ),
        WallpaperModel(
          id: 'galaxy_deep',
          name: 'Deep Galaxy',
          description: 'Stunning deep-space galaxy simulation',
          type: WallpaperType.galaxy,
          colors: [0xFF0D0D2B, 0xFF1A1A4E, 0xFF7C4DFF],
          previewEmoji: '🌌',
          thumbnailAsset: 'galaxy_deep',
        ),
        WallpaperModel(
          id: 'neon_pulse',
          name: 'Neon Pulse',
          description: 'Pulsating neon rings and energy waves',
          type: WallpaperType.neonPulse,
          colors: [0xFF0A0A0A, 0xFF00E5FF, 0xFFFF4081],
          previewEmoji: '⚡',
          thumbnailAsset: 'neon_pulse',
        ),
        WallpaperModel(
          id: 'matrix_rain',
          name: 'Matrix Rain',
          description: 'Classic green digital rain falling code',
          type: WallpaperType.matrixRain,
          colors: [0xFF000000, 0xFF00C853, 0xFF69F0AE],
          previewEmoji: '💻',
          thumbnailAsset: 'matrix_rain',
        ),
        WallpaperModel(
          id: 'aurora_green',
          name: 'Aurora Borealis',
          description: 'Beautiful northern lights aurora animation',
          type: WallpaperType.aurora,
          colors: [0xFF1A1A2E, 0xFF00C853, 0xFF40C4FF],
          previewEmoji: '🌌',
          thumbnailAsset: 'aurora_green',
        ),
        WallpaperModel(
          id: 'fluid_colors',
          name: 'Fluid Colors',
          description: 'Mesmerizing fluid color blending animation',
          type: WallpaperType.fluidColors,
          colors: [0xFFFF6B6B, 0xFFFFE66D, 0xFF4ECDC4],
          previewEmoji: '🎨',
          thumbnailAsset: 'fluid_colors',
        ),
        WallpaperModel(
          id: 'neon_forest',
          name: 'Neon Forest',
          description: 'Glowing neon trees in a dark mystical forest',
          type: WallpaperType.aurora,
          colors: [0xFF0A1628, 0xFF39FF14, 0xFF00FFFF],
          previewEmoji: '🌲',
          thumbnailAsset: 'neon_forest',
        ),
      ];
}
