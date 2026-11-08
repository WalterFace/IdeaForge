import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';
import 'product_details_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchController = TextEditingController();
  MenuCategory? _category;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _quickAdd(BuildContext context, MenuItem item) {
    final state = AppStateScope.read(context);
    if (item.hasCustomizations) {
      showProductDetails(context, item);
      return;
    }
    state.addToCart(item);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('${item.name} added to cart')));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.searchMenu(query: _query, category: _category);
    final popularIds = state.popularPicks.take(3).map((p) => p.item.id).toSet();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search drinks, bakery, snacks…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(
                  label: 'All',
                  icon: Icons.apps_rounded,
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in MenuCategory.values)
                  _CategoryChip(
                    label: c.label,
                    icon: c.icon,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              '${items.length} item${items.length == 1 ? '' : 's'}'
              '${_category != null ? ' in ${_category!.label}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Nothing matches',
              message: 'Try a different search or category.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 640 ? 3 : 2;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = items[i];
                      return ProductCard(
                        item: item,
                        badge: item.id == state.drinkOfTheMonth.id
                            ? 'Featured'
                            : popularIds.contains(item.id)
                                ? 'Popular'
                                : null,
                        onTap: () => showProductDetails(context, item),
                        onAdd: () => _quickAdd(context, item),
                      );
                    },
                    childCount: items.length,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.espresso : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.espresso : AppColors.warmGrayDark,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? AppColors.caramel : AppColors.mocha),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? AppColors.oatCream : AppColors.espresso,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
