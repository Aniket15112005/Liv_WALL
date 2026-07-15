import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../services/video_wallpaper_service.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  static const double _maxClipSeconds = 30;

  String? _sourcePath;
  VideoPlayerController? _controller;
  RangeValues _range = const RangeValues(0, 10);
  double _totalSeconds = 10;
  WallpaperQuality _quality = WallpaperQuality.balanced;
  final _titleController = TextEditingController(text: 'My Wallpaper');
  bool _isPreparingVideo = false;

  @override
  void dispose() {
    _controller?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _isPreparingVideo = true);

    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();

    final total = controller.value.duration.inMilliseconds / 1000;
    final clipLength = total < _maxClipSeconds ? total : _maxClipSeconds;

    _controller?.dispose();

    setState(() {
      _sourcePath = path;
      _controller = controller..setLooping(true)..play();
      _totalSeconds = total;
      _range = RangeValues(0, clipLength);
      _isPreparingVideo = false;
    });
  }

  Future<void> _saveWallpaper() async {
    if (_sourcePath == null) return;
    final service = context.read<VideoWallpaperService>();

    final wallpaper = await service.processAndSave(
      sourcePath: _sourcePath!,
      title: _titleController.text,
      start: _range.start,
      end: _range.end,
      quality: _quality,
    );

    if (!mounted) return;

    if (wallpaper != null) {
      Navigator.pop(context, wallpaper);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.errorMessage ?? 'Could not save the video.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<VideoWallpaperService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: const Text('Add Video Wallpaper'),
      ),
      body: SafeArea(
        child: _sourcePath == null
            ? _buildPickerPrompt()
            : _buildEditor(service),
      ),
    );
  }

  Widget _buildPickerPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_call_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose a video from your phone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll help you trim it and fit it perfectly to your screen.",
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _isPreparingVideo
                ? const CircularProgressIndicator(color: Color(0xFF6C63FF))
                : ElevatedButton(
                    onPressed: _pickVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Pick a Video'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(VideoWallpaperService service) {
    final controller = _controller!;
    final clipSeconds = _range.end - _range.start;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 9 / 16
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Trim clip',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  Text(
                    '${clipSeconds.toStringAsFixed(1)}s selected',
                    style: const TextStyle(
                        color: Color(0xFF8B83FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              RangeSlider(
                values: _range,
                min: 0,
                max: _totalSeconds,
                activeColor: const Color(0xFF6C63FF),
                inactiveColor: Colors.white12,
                onChanged: (values) {
                  final span = values.end - values.start;
                  if (span > _maxClipSeconds) return;
                  setState(() => _range = values);
                  controller.seekTo(
                    Duration(milliseconds: (values.start * 1000).round()),
                  );
                },
              ),
              Text(
                'Max ${_maxClipSeconds.toInt()}s — kept short so it plays smoothly and stays small on your device.',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 16),
              const Text('Quality',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: WallpaperQuality.values.map((q) {
                  final selected = q == _quality;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _quality = q),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _qualityLabel(q),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: service.isProcessing ? null : _saveWallpaper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: service.isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                                value: service.processingProgress > 0
                                    ? service.processingProgress
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Processing…'),
                          ],
                        )
                      : const Text('Save to Library'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _qualityLabel(WallpaperQuality q) {
    switch (q) {
      case WallpaperQuality.dataSaver:
        return 'Data saver';
      case WallpaperQuality.balanced:
        return 'Balanced';
      case WallpaperQuality.best:
        return 'Best';
    }
  }
}
