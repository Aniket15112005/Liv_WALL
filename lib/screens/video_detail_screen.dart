import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/saved_wallpaper.dart';
import '../services/video_wallpaper_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final SavedWallpaper wallpaper;

  const VideoDetailScreen({super.key, required this.wallpaper});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _controller;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      File(widget.wallpaper.videoPath),
    )
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<VideoWallpaperService>();
    final isActive = service.activeWallpaperId == widget.wallpaper.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      // Prevent the scaffold body from shrinking when a keyboard is visible
      // (e.g. after dismissing the rename dialog on a previous screen).
      // Without this, the Stack collapses and the Positioned(bottom: 0)
      // bottom panel ends up overlapping the top buttons.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.92),
                  ],
                  stops: const [0.0, 0.2, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _glassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _glassButton(
                    icon: Icons.edit_rounded,
                    onTap: () => _showRenameDialog(context, service),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(context, service, isActive),
          ),
          if (_isApplying)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    SizedBox(height: 16),
                    Text(
                      'Opening system wallpaper chooser…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel(
      BuildContext context, VideoWallpaperService service, bool isActive) {
    final w = widget.wallpaper;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              w.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${w.formattedDuration} · ${w.formattedSize}',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (isActive)
                  Expanded(child: _buildRemoveButton(service))
                else
                  Expanded(child: _buildApplyButton(service)),
                const SizedBox(width: 12),
                _buildDeleteButton(context, service),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(VideoWallpaperService service) {
    return GestureDetector(
      onTap: () => _apply(service),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wallpaper_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Set as Live Wallpaper',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(VideoWallpaperService service) {
    return GestureDetector(
      onTap: () => _removeActive(service),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Active · Tap to remove',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(
      BuildContext context, VideoWallpaperService service) {
    return GestureDetector(
      onTap: () => _confirmDelete(context, service),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _apply(VideoWallpaperService service) async {
    setState(() => _isApplying = true);
    final success = await service.applyWallpaper(widget.wallpaper);
    if (!mounted) return;
    setState(() => _isApplying = false);
    if (success) {
      _showSnack('Choose "Set wallpaper" to finish applying it.',
          Colors.green.shade700);
    } else {
      _showSnack(
          service.errorMessage ?? 'Failed to apply', Colors.red.shade700);
    }
  }

  Future<void> _removeActive(VideoWallpaperService service) async {
    final success = await service.removeActiveWallpaper();
    if (!mounted) return;
    _showSnack(
      success
          ? 'Live wallpaper removed.'
          : (service.errorMessage ?? 'Failed to remove'),
      success ? Colors.green.shade700 : Colors.red.shade700,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, VideoWallpaperService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14142B),
        title: const Text('Delete wallpaper?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'This permanently deletes "${widget.wallpaper.title}" from your library.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.deleteWallpaper(widget.wallpaper.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showRenameDialog(
      BuildContext context, VideoWallpaperService service) async {
    final controller = TextEditingController(text: widget.wallpaper.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14142B),
        title: const Text('Rename', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.trim().isNotEmpty) {
      await service.renameWallpaper(widget.wallpaper.id, newTitle);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
