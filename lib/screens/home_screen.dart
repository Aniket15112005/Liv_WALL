import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/wallpaper_service.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/category_chip.dart';
import 'wallpaper_detail_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<WallpaperService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _WallpaperGalleryTab(),
          _FavoritesTab(),
          _ActiveWallpaperTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(service),
    );
  }

  Widget _buildBottomNav(WallpaperService service) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.white38,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.wallpaper_rounded),
            label: 'Wallpapers',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: service.favorites.isNotEmpty,
              label: Text('${service.favorites.length}'),
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.phone_android_rounded),
            label: 'Active',
          ),
        ],
      ),
    );
  }
}

class _WallpaperGalleryTab extends StatelessWidget {
  const _WallpaperGalleryTab();

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<WallpaperService>(context);

    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: _buildCategoryRow(context, service),
        ),
        _buildWallpaperGrid(context, service),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A1A),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A3A), Color(0xFF0A0A1A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Live Wallpapers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: const Text(
                      'Animate your home screen',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, WallpaperService service) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: service.categories.length,
        itemBuilder: (ctx, i) {
          final cat = service.categories[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              label: cat,
              isSelected: service.selectedCategory == cat,
              onTap: () => service.setCategory(cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWallpaperGrid(BuildContext context, WallpaperService service) {
    final wallpapers = service.filteredWallpapers;
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            return FadeInUp(
              delay: Duration(milliseconds: i * 60),
              child: WallpaperCard(
                wallpaper: wallpapers[i],
                isActive:
                    service.activeWallpaper?.id == wallpapers[i].id,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WallpaperDetailScreen(
                      wallpaper: wallpapers[i],
                    ),
                  ),
                ),
                onFavorite: () =>
                    service.toggleFavorite(wallpapers[i]),
              ),
            );
          },
          childCount: wallpapers.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return const FavoritesScreen();
  }
}

class _ActiveWallpaperTab extends StatelessWidget {
  const _ActiveWallpaperTab();

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<WallpaperService>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Wallpaper',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (service.activeWallpaper == null)
              _buildNoActiveCard(context)
            else
              _buildActiveCard(context, service),
            const SizedBox(height: 24),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveCard(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wallpaper_rounded, color: Colors.white30, size: 48),
          SizedBox(height: 12),
          Text(
            'No active live wallpaper',
            style: TextStyle(color: Colors.white54),
          ),
          SizedBox(height: 4),
          Text(
            'Pick one from the gallery',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context, WallpaperService service) {
    final w = service.activeWallpaper!;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: w.colors.map((c) => Color(c)).toList(),
    );

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(w.colors.first).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Text(
              w.previewEmoji,
              style: const TextStyle(fontSize: 100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Active',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  w.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  w.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 18),
              SizedBox(width: 8),
              Text(
                'How to set as Live Wallpaper',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _step('1', 'Tap any wallpaper and press "Apply"'),
          _step('2', 'Select "Live Wallpaper" when prompted'),
          _step('3', 'Choose "Set Wallpaper" to confirm'),
          _step('4', 'Set for Home, Lock, or Both screens'),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
