import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import '../widgets/adhkar_card.dart';
import 'category_adhkar_screen.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryAdhkarScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSearching = provider.searchQuery.isNotEmpty;

    // Sync controller with provider (e.g. after tab-switch clears search)
    if (_searchController.text != provider.searchQuery) {
      _searchController.text = provider.searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Row(
            children: [
              Icon(OctIcons.book, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'المفردون',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          floating: false,
          pinned: true,
          snap: false,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70.0),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'بحث في الأذكار...',
                  prefixIcon: const Icon(OctIcons.search),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            provider.clearSearch();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                onChanged: (value) => provider.setSearchQuery(value),
              ),
            ),
          ),
        ),

        // Loading state
        if (provider.isLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل الأذكار...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )

        // Error state
        else if (provider.loadError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    OctIcons.alert,
                    size: 64,
                    color: colorScheme.error.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.loadError!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => provider.loadAdhkarData(),
                    icon: const Icon(OctIcons.sync, size: 18),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          )

        // Search results
        else if (isSearching) ...[
          if (provider.filteredAdhkarList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      OctIcons.search,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد نتائج',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return AdhkarCard(item: provider.filteredAdhkarList[index]);
                  },
                  childCount: provider.filteredAdhkarList.length,
                ),
              ),
            ),
        ]

        // Normal: quick-access + category grid
        else ...[
          // Quick-access buttons for morning/evening adhkar
          SliverToBoxAdapter(
            child: _QuickAccessButtons(
              categories: provider.categories,
              onOpenCategory: (cat) => _openCategory(context, cat),
            ),
          ),

          // Category grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = provider.categories[index];
                  return CategoryCard(
                    category: category,
                    onTap: () => _openCategory(context, category),
                  );
                },
                childCount: provider.categories.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ],
    );
  }
}

class _QuickAccessButtons extends StatelessWidget {
  final List<String> categories;
  final void Function(String category) onOpenCategory;

  const _QuickAccessButtons({
    required this.categories,
    required this.onOpenCategory,
  });

  @override
  Widget build(BuildContext context) {
    final morningCat = categories.cast<String?>().firstWhere(
          (c) => c!.contains('الصباح'),
          orElse: () => null,
        );
    final eveningCat = categories.cast<String?>().firstWhere(
          (c) => c!.contains('المساء'),
          orElse: () => null,
        );

    if (morningCat == null && eveningCat == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (morningCat != null)
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => onOpenCategory(morningCat),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                  foregroundColor:
                      isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(OctIcons.sun,
                        size: 18,
                        color: isDark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'أذكار الصباح',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (morningCat != null && eveningCat != null)
            const SizedBox(width: 12),
          if (eveningCat != null)
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => onOpenCategory(eveningCat),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                  foregroundColor:
                      isDark ? Colors.indigo.shade300 : Colors.indigo.shade700,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(OctIcons.moon,
                        size: 18,
                        color: isDark
                            ? Colors.indigo.shade300
                            : Colors.indigo.shade700),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'أذكار المساء',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
