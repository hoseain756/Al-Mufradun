import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import '../widgets/adhkar_card.dart';
import 'category_adhkar_screen.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSearching = provider.searchQuery.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // M3: Regular Top App Bar
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
          // M3: Search bar below app bar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70.0),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              // M3: Filled text field with theme-defined decoration
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'بحث في الأذكار...',
                  prefixIcon: const Icon(OctIcons.search),
                  // M3: Uses inputDecorationTheme from AppTheme
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                onChanged: (value) => provider.setSearchQuery(value),
              ),
            ),
          ),
        ),

        // Search results
        if (isSearching) ...[
          if (provider.filteredAdhkarList.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      OctIcons.search,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
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
              padding: const EdgeInsets.all(16), // M3: 16dp standard margin
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return AdhkarCard(item: provider.filteredAdhkarList[index]);
                  },
                  childCount: provider.filteredAdhkarList.length,
                ),
              ),
            ),
        ] else ...[
          // Category grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12, // M3: 4dp grid spacing
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = provider.categories[index];
                  return CategoryCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryAdhkarScreen(category: category),
                        ),
                      );
                    },
                  );
                },
                childCount: provider.categories.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
