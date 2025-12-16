import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/app_service.dart';
import '../../data/models/app_info_model.dart';

class AppControlScreen extends StatefulWidget {
  final String childId;
  const AppControlScreen({super.key, required this.childId});

  @override
  State<AppControlScreen> createState() => _AppControlScreenState();
}

class _AppControlScreenState extends State<AppControlScreen>
    with TickerProviderStateMixin {
  final AppService _appService = AppService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Blocked', 'Allowed'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'App Control',
                style: TextStyle(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Category Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: child,
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(category),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                          backgroundColor: colorScheme.surface,
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // App List
          StreamBuilder<List<AppInfoModel>>(
            stream: _appService.streamApps(user.uid, widget.childId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading apps...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              var apps = snapshot.data ?? [];

              // Filter by search
              if (_searchQuery.isNotEmpty) {
                apps = apps
                    .where(
                      (app) =>
                          app.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          app.packageName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();
              }

              // Filter by category
              if (_selectedCategory == 'Blocked') {
                apps = apps.where((app) => app.isLocked).toList();
              } else if (_selectedCategory == 'Allowed') {
                apps = apps.where((app) => !app.isLocked).toList();
              }

              if (apps.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apps_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No apps found'
                              : 'No apps synced yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final app = apps[index];
                    return _AnimatedAppTile(
                      app: app,
                      index: index,
                      onToggle: (value) {
                        _appService.toggleAppLock(
                          user.uid,
                          widget.childId,
                          app.packageName.replaceAll('.', '_'),
                          !value,
                        );
                      },
                    );
                  }, childCount: apps.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Animated App Tile with staggered animation
class _AnimatedAppTile extends StatelessWidget {
  final AppInfoModel app;
  final int index;
  final ValueChanged<bool> onToggle;

  const _AnimatedAppTile({
    required this.app,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: app.isLocked
                ? Colors.red.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: app.isLocked
                    ? [Colors.red.shade100, Colors.red.shade50]
                    : [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withOpacity(0.5),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.android,
              color: app.isLocked ? Colors.red : colorScheme.primary,
            ),
          ),
          title: Text(
            app.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: app.isLocked ? TextDecoration.lineThrough : null,
              color: app.isLocked ? Colors.grey : colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            app.packageName,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _CustomSwitch(value: !app.isLocked, onChanged: onToggle),
        ),
      ),
    );
  }
}

// Custom animated switch
class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value
              ? LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: value ? null : Colors.grey.shade300,
          boxShadow: value
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  value ? Icons.check : Icons.close,
                  key: ValueKey(value),
                  size: 14,
                  color: value ? colorScheme.primary : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
