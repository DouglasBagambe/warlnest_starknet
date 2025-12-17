import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';
import 'filter_screen.dart';
import 'explore_screen.dart';
import 'compare_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'all_properties_screen.dart';
import 'loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Property> _featuredProperties = [];
  List<Property> _recentProperties = [];
  List<Property> _allProperties = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Apartments', 'Houses', 'Condos', 'Villas'];
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.calculate_rounded, 'label': 'Mortgage', 'color': Colors.blue},
    {'icon': Icons.location_on_rounded, 'label': 'Map View', 'color': Colors.green},
    {'icon': Icons.analytics_rounded, 'label': 'Market', 'color': Colors.orange},
    {'icon': Icons.bookmark_rounded, 'label': 'Saved', 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProperties();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final results = await Future.wait([
        ApiService.getFeaturedProperties(),
        ApiService.getRecentProperties(),
        ApiService.getAllProperties(),
      ]);

      setState(() {
        _featuredProperties = results[0];
        _recentProperties = results[1];
        _allProperties = results[2];
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _featuredProperties = [];
        _recentProperties = [];
        _allProperties = [];
        _isLoading = false;
      });
      _animationController.forward();
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    body: _isLoading ? const LoadingScreen() : _buildMainContent(),
    floatingActionButton: _buildFloatingActionButton(),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
}

  // Widget _buildLoadingScreen() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topCenter,
  //         end: Alignment.bottomCenter,
  //         colors: [
  //           Theme.of(context).colorScheme.primary.withOpacity(0.1),
  //           Theme.of(context).colorScheme.surface,
  //         ],
  //       ),
  //     ),
  //     child: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(32),
  //             decoration: BoxDecoration(
  //               color: Theme.of(context).colorScheme.surface,
  //               shape: BoxShape.circle,
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
  //                   blurRadius: 30,
  //      

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const FavoritesScreen(),
          const ExploreScreen(),
          const CompareScreen(),
          const SettingsScreen(),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadProperties,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildDynamicAppBar(),
          _buildWelcomeHero(),
          _buildQuickActions(),
          _buildCategoryFilter(),
          _buildFeaturedSection(),
          _buildRecentSection(),
          _buildAllPropertiesSection(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildDynamicAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/logo_name.svg',
              width: 320,
              height: 64,
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FilterScreen()),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildWelcomeHero() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Your Dream Home',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_allProperties.length} premium properties available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _quickActions.map((action) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(action['icon'], color: action['color'], size: 24),
                  const SizedBox(height: 8),
                  Text(
                    action['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Featured Properties',
            'Premium handpicked listings',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'Featured Properties',
                  initialProperties: _featuredProperties,
                  showFeaturedOnly: true,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: _featuredProperties.isEmpty
                ? _buildEmptyState('No featured properties', Icons.star_outline)
                : _buildHorizontalPropertyList(_featuredProperties),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Recent Listings',
            'Latest properties on market',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'Recent Listings',
                  initialProperties: _recentProperties,
                  showFeaturedOnly: false,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: _recentProperties.isEmpty
                ? _buildEmptyState('No recent properties', Icons.star_outline)
                : _buildHorizontalPropertyList(_recentProperties),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPropertiesSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'All Properties',
            'Browse our complete collection',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'All Properties',
                  initialProperties: _allProperties,
                  showFeaturedOnly: false,
                ),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _allProperties.take(6).length,
            itemBuilder: (context, index) {
              return PropertyCard(propertyId: _allProperties[index].id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPropertyList(List<Property> properties) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = screenWidth > 600 ? 320.0 : screenWidth * 0.75;
        
        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 16),
          child: PropertyCard(propertyId: properties[index].id),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FilterScreen()),
        ),
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Filter'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.favorite_rounded, 'Favorites'),
              _buildNavItem(2, Icons.explore_rounded, 'Explore'),
              _buildNavItem(3, Icons.compare_arrows_rounded, 'Compare'),
              _buildNavItem(4, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            index == 0
                ? SvgPicture.asset(
                    'assets/images/app_logo.svg',
                    width: 24,
                    height: 24,
                    colorFilter: isSelected
                        ? null
                        : ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}