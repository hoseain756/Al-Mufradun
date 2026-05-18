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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // M3: Horizontal app bar (icon + title)
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
          SliverPadding(
            padding: const EdgeInsets.all(16), // M3: 16dp standard margin
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = adhkarList[index];
                  // M3: AdhkarCard handles its own card styling
                  return AdhkarCard(
                    key: ValueKey(item.id),
                    item: item,
                  );
                },
                childCount: adhkarList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
