class HistoryEntry {
  final String id;
  final String wallpaperId;
  final String title;
  final String videoPath;
  final DateTime appliedAt;

  HistoryEntry({
    required this.id,
    required this.wallpaperId,
    required this.title,
    required this.videoPath,
    required this.appliedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'wallpaperId': wallpaperId,
        'title': title,
        'videoPath': videoPath,
        'appliedAt': appliedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        wallpaperId: json['wallpaperId'] as String,
        title: json['title'] as String,
        // Older saved history entries used 'thumbnailPath' — fall back to
        // empty rather than crash if this entry predates the field rename.
        videoPath: (json['videoPath'] ?? json['thumbnailPath'] ?? '') as String,
        appliedAt: DateTime.parse(json['appliedAt'] as String),
      );

  String get formattedWhen {
    final now = DateTime.now();
    final diff = now.difference(appliedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${appliedAt.day.toString().padLeft(2, '0')}/'
        '${appliedAt.month.toString().padLeft(2, '0')}/'
        '${appliedAt.year}';
  }
}
