import 'package:flutter/material.dart';

import '../services/rush_mode_engine.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/content_frame.dart';
import '../widgets/product_art.dart';
import '../widgets/section_header.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

/// Rush Mode: pick a time window, get items estimated to be ready in time.
class RushModeScreen extends StatefulWidget {
  const RushModeScreen({super.key, this.initialWindow = 15});

  final int initialWindow;

  @override
  State<RushModeScreen> createState() => _RushModeScreenState();
}

class _RushModeScreenState extends State<RushModeScreen> {
  late int _window = widget.initialWindow;
  bool _showExcluded = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final result = state.rushRecommendations(_window);
    final likely = result.recommendations
        .where((r) => r.fit == RushFit.likelyFits)
        .toList();
    final tight = result.recommendations
        .where((r) => r.fit == RushFit.mayBeTight)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rush Mode'),
        actions: [
          CartIconButtonCompact(count: state.cartCount),
          const SizedBox(width: 6),
        ],
      ),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  decoration:
                      const BoxDecoration(gradient: AppColors.caramelGradient),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 180,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Running late for class?\nWe\'ve got you.',
                              style: TextStyle(
                                color: AppColors.espresso,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tell us how much time you have. We\'ll help you pick something quick.',
                              style: TextStyle(
                                color:
                                    AppColors.espresso.withValues(alpha: 0.85),
                                fontSize: 14.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'TIME BEFORE CLASS',
                              style: TextStyle(
                                color:
                                    AppColors.espresso.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final w in RushModeEngine.windows) ...[
                                  Expanded(
                                    child: _WindowChip(
                                      minutes: w,
                                      selected: _window == w,
                                      onTap: () => setState(() => _window = w),
                                    ),
                                  ),
                                  if (w != RushModeEngine.windows.last)
                                    const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: SurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate_outlined,
                            size: 18, color: AppColors.mocha),
                        const SizedBox(width: 8),
                        Text('How we estimate',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimated wait = simulated queue delay (${result.queueDelayMinutes} min for '
                      '${state.ordersInQueue} orders in queue) + item preparation time. '
                      'Items ready with ${RushModeEngine.comfortBufferMinutes}+ minutes to spare are "Likely fits".',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    const DemoLabel(
                      'Demo estimates only. Actual cafe preparation times may vary. Rule-based, not machine learning.',
                    ),
                  ],
                ),
              ),
            ),
            if (likely.isNotEmpty) ...[
              SectionHeader(
                title: 'Likely fits',
                subtitle: '${likely.length} items ready within $_window min',
              ),
              for (final r in likely)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _RecommendationTile(rec: r),
                ),
            ],
            if (tight.isNotEmpty) ...[
              SectionHeader(
                title: 'May be tight',
                subtitle: 'Cutting it close for $_window min',
              ),
              for (final r in tight)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _RecommendationTile(rec: r),
                ),
            ],
            if (result.recommendations.isEmpty)
              const EmptyState(
                icon: Icons.hourglass_bottom_rounded,
                title: 'Nothing fits that window',
                message: 'The queue is long right now. Try a bigger window.',
              ),
            if (result.excluded.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showExcluded = !_showExcluded),
                      icon: Icon(_showExcluded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded),
                      label: Text(
                        '${result.excluded.length} item${result.excluded.length == 1 ? '' : 's'} would take too long',
                      ),
                    ),
                    if (_showExcluded)
                      for (final r in result.excluded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecommendationTile(rec: r, muted: true),
                        ),
                  ],
                ),
              ),
            if (state.cartCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppButton(
                  label:
                      'Go to cart (${state.cartCount}) · ${formatAed(state.total)}',
                  icon: Icons.shopping_bag_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? AppColors.espresso : Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$minutes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.caramel : AppColors.espresso,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'min',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.oatCream.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.rec, this.muted = false});

  final RushRecommendation rec;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.read(context);
    final theme = Theme.of(context);
    final item = rec.item;
    final (Color fitColor, Color fitText) = switch (rec.fit) {
      RushFit.likelyFits => (AppColors.softGreen, Colors.white),
      RushFit.mayBeTight => (AppColors.caramel, AppColors.espresso),
      RushFit.tooLong => (AppColors.warmGrayDark, AppColors.textSecondary),
    };

    return Opacity(
      opacity: muted ? 0.7 : 1,
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        onTap: () => showProductDetails(context, item, rushContext: true),
        child: Row(
          children: [
            ProductArtView(art: item.art, size: 64, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Pill(
                        label: rec.fit.label,
                        color: fitColor,
                        textColor: fitText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.mocha),
                      const SizedBox(width: 4),
                      Text(
                        '~${rec.estimatedMinutes} min',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.espresso,
                        ),
                      ),
                      Text(
                        '  (${rec.estimatedMinutes - item.prepMinutes} queue + ${item.prepMinutes} prep)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatAed(item.price),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.mocha,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: () => showProductDetails(context, item,
                            rushContext: true),
                        child: const Text('Customize'),
                      ),
                      const SizedBox(width: 4),
                      AppButton(
                        label: 'Add',
                        icon: Icons.add_rounded,
                        expanded: false,
                        dense: true,
                        onPressed: () {
                          state.addToCart(
                            item,
                            size: item.sizes.isEmpty
                                ? null
                                : item.sizes.length > 1
                                    ? item.sizes[1]
                                    : item.sizes.first,
                            milk: item.milks.isEmpty ? null : item.milks.first,
                          );
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('${item.name} added to cart'),
                                action: SnackBarAction(
                                  label: 'Checkout',
                                  textColor: AppColors.caramel,
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const CartScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cart icon for secondary screens (avoids importing the shell).
class CartIconButtonCompact extends StatelessWidget {
  const CartIconButtonCompact({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CartScreen()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.caramel,
        textColor: AppColors.espresso,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}
