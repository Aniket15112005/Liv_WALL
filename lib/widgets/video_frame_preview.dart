import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shows a single paused frame from a video file as a lightweight visual
/// preview — used instead of a separately generated thumbnail image, so
/// the app doesn't depend on an extra native thumbnail-generation plugin.
class VideoFramePreview extends StatefulWidget {
  final String videoPath;
  final BoxFit fit;

  const VideoFramePreview({
    super.key,
    required this.videoPath,
    this.fit = BoxFit.cover,
  });

  @override
  State<VideoFramePreview> createState() => _VideoFramePreviewState();
}

class _VideoFramePreviewState extends State<VideoFramePreview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.videoPath.isEmpty || !File(widget.videoPath).existsSync()) {
      setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.file(File(widget.videoPath));
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.pause();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: const Color(0xFF1C1C3A),
        child: const Icon(
          Icons.movie_creation_outlined,
          color: Colors.white24,
          size: 40,
        ),
      );
    }
    if (!_ready || _controller == null) {
      return Container(
        color: const Color(0xFF1C1C3A),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white24,
            ),
          ),
        ),
      );
    }
    return FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
