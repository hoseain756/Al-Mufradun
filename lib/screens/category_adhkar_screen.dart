import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import '../widgets/adhkar_card.dart';

class CategoryAdhkarScreen extends StatelessWidget {
  final String category;

  const CategoryAdhkarScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final adhkarList = provider.getAdhkarByCategory(category);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final completedCount =
        adhkarList.where((item) => provider.isDhikrCompleted(item)).length;
    final totalCount = adhkarList.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: false,
            title: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(OctIcons.arrow_right),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Progress header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount من $totalCount مكتمل',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(OctIcons.sync, size: 20),
                    tooltip: 'إعادة تعيين العداد',
                    onPressed: () {
                      for (final item in adhkarList) {
                        provider.resetDhikrCount(item.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Adhkar list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = adhkarList[index];
                  return AdhkarCard(
                    key: ValueKey(item.id),
                    item: item,
                    categoryList: adhkarList,
                    indexInCategory: index,
                  );
                },
                childCount: adhkarList.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}
