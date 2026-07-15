import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_service.dart';
import '../widgets/animated_preview.dart';

class WallpaperDetailScreen extends StatefulWidget {
  final WallpaperModel wallpaper;

  const WallpaperDetailScreen({super.key, required this.wallpaper});

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<WallpaperService>(context);
    final isActive = service.activeWallpaper?.id == widget.wallpaper.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Full-screen animated preview
          AnimatedPreview(wallpaper: widget.wallpaper),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.2, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Top bar
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
                    icon: widget.wallpaper.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: widget.wallpaper.isFavorite
                        ? Colors.pinkAccent
                        : Colors.white,
                    onTap: () => service.toggleFavorite(widget.wallpaper),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: _buildBottomPanel(context, service, isActive),
            ),
          ),

          // Loading overlay
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
                      'Applying wallpaper...',
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel(
      BuildContext context, WallpaperService service, bool isActive) {
    final w = widget.wallpaper;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5)),
            ),
            child: Text(
              w.type.name.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            w.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            w.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Color preview
          Row(
            children: [
              const Text(
                'Colors  ',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              ...w.colors.map(
                (c) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              if (isActive)
                Expanded(
                  child: _buildActiveButton(),
                )
              else ...[
                Expanded(
                  child: _buildApplyButton(service),
                ),
                const SizedBox(width: 12),
                _buildPickerButton(service),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(WallpaperService service) {
    return GestureDetector(
      onTap: () => _applyWallpaper(service),
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
                'Apply Live Wallpaper',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
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
              'Currently Active',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton(WallpaperService service) {
    return GestureDetector(
      onTap: () => service.openWallpaperPicker(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Icon(
          Icons.settings_rounded,
          color: Colors.white54,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _applyWallpaper(WallpaperService service) async {
    setState(() => _isApplying = true);

    final success = await service.applyWallpaper(widget.wallpaper);

    if (mounted) {
      setState(() => _isApplying = false);
      if (success) {
        _showSuccessSnackbar();
      } else {
        _showErrorSnackbar(service.errorMessage ?? 'Failed to apply');
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Live wallpaper applied! Go to home screen to see it.'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
