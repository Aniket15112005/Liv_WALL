import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/wallpaper_service.dart';
import '../widgets/wallpaper_card.dart';
import 'wallpaper_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<WallpaperService>(context);
    final favorites = service.favorites;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: FadeInDown(
              child: const Text(
                'Favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (favorites.isEmpty)
            Expanded(child: _buildEmptyState())
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: favorites.length,
                itemBuilder: (ctx, i) {
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 80),
                    child: WallpaperCard(
                      wallpaper: favorites[i],
                      isActive:
                          service.activeWallpaper?.id == favorites[i].id,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WallpaperDetailScreen(
                            wallpaper: favorites[i],
                          ),
                        ),
                      ),
                      onFavorite: () =>
                          service.toggleFavorite(favorites[i]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: Colors.pinkAccent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Favorites Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap ♡ on any wallpaper to\nadd it to your favorites',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
