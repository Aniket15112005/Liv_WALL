class SavedWallpaper {
  final String id;
  final String title;
  final String videoPath;
  final String thumbnailPath;
  final int durationMs;
  final int sizeBytes;
  final DateTime createdAt;

  SavedWallpaper({
    required this.id,
    required this.title,
    required this.videoPath,
    required this.thumbnailPath,
    required this.durationMs,
    required this.sizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'videoPath': videoPath,
        'thumbnailPath': thumbnailPath,
        'durationMs': durationMs,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedWallpaper.fromJson(Map<String, dynamic> json) => SavedWallpaper(
        id: json['id'] as String,
        title: json['title'] as String,
        videoPath: json['videoPath'] as String,
        thumbnailPath: json['thumbnailPath'] as String,
        durationMs: json['durationMs'] as int,
        sizeBytes: json['sizeBytes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get formattedSize {
    final mb = sizeBytes / (1024 * 1024);
    if (mb < 1) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
