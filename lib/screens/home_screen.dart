import 'package:flutter/material.dart';

import '../models/cafe_order.dart';
import '../models/menu_item.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/product_art.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';
import 'demo_controls_screen.dart';
import 'product_details_screen.dart';
import 'rush_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final active = state.activeOrder;
    final dotm = state.drinkOfTheMonth;
    final popular = state.popularPicks.take(8).toList();
    final nextEvent = state.events.first;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${greetingFor(now)}, ${state.nickname}',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Your campus, in a cup',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (active != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ActiveOrderCard(
              order: active,
              onTap: () => state.setTab(2),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LoyaltyCard(
            account: state.loyalty,
            nickname: state.nickname,
            onTap: () => state.setTab(3),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Order Now',
                  icon: Icons.local_cafe_rounded,
                  onPressed: () => state.setTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Demo Controls',
                  icon: Icons.tune_rounded,
                  style: AppButtonStyle.ghost,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DemoControlsScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _RushModeCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RushModeScreen()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PromoSpotlight(
            onOpen: () => showProductDetails(context, dotm),
            onAdd: () {
              state.addToCart(dotm, size: 'Medium', milk: 'Whole milk');
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(content: Text('${dotm.name} added to cart')),
                );
            },
          ),
        ),
        SectionHeader(
          title: 'Popular Now',
          subtitle: 'Ranked from sample + demo order history',
          actionLabel: 'Menu',
          onAction: () => state.setTab(1),
        ),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: popular.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final pick = popular[i];
              return ProductTile(
                item: pick.item,
                caption: '${pick.quantitySold} sold · ${formatAed(pick.item.price)}',
                onTap: () => showProductDetails(context, pick.item),
                trailing: i == 0
                    ? const Icon(Icons.local_fire_department_rounded,
                        size: 16, color: AppColors.caramel)
                    : null,
              );
            },
          ),
        ),
        SectionHeader(
          title: 'On Campus',
          subtitle: 'Sample club events (demo)',
          actionLabel: 'See all',
          onAction: () => state.setTab(4),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SurfaceCard(
            gradient: AppColors.greenGradient,
            onTap: () => state.setTab(4),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(nextEvent.category.icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextEvent.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${nextEvent.club} · ${formatShortDate(nextEvent.date)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'ideaForge × AIRC · offline prototype · all data is sample data',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _RushModeCard extends StatelessWidget {
  const _RushModeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppColors.caramelGradient),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -30,
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 150,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Pill(
                              label: 'NEW',
                              color: AppColors.espresso,
                              textColor: AppColors.oatCream,
                              icon: Icons.bolt_rounded,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Rush Mode',
                              style: TextStyle(
                                color: AppColors.espresso,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Running late for class? Tell us how long you have and we\'ll pick something that can be ready in time.',
                              style: TextStyle(
                                color: AppColors.espresso.withValues(alpha: 0.85),
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AppButton(
                              label: 'I\'m in a rush',
                              icon: Icons.timer_rounded,
                              expanded: false,
                              dense: true,
                              onPressed: onTap,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _PromoSpotlight extends StatelessWidget {
  const _PromoSpotlight({required this.onOpen, required this.onAdd});

  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onOpen,
      child: Row(
        children: [
          const ProductArtView(art: ProductArt.latte, size: 96, radius: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Pill(
                  label: 'DRINK OF THE MONTH',
                  color: AppColors.caramel,
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 8),
                Text('Caramel Cloud Latte', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Salted caramel cold foam over a silky latte. ${formatAed(22)}.',
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AppButton(
                      label: 'Add to cart',
                      expanded: false,
                      dense: true,
                      onPressed: onAdd,
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onOpen,
                      child: const Text('Customize'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order, required this.onTap});

  final CafeOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final isReady = order.status == OrderStatus.ready;
    final wait = order.estimatedWaitMinutes(state.prepMinutesFor);
    return SurfaceCard(
      onTap: onTap,
      border: Border.all(
        color: isReady ? AppColors.softGreen : AppColors.caramel,
        width: 1.5,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isReady ? AppColors.softGreen : AppColors.caramel)
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isReady ? Icons.notifications_active_rounded : Icons.coffee_maker_rounded,
              color: isReady ? AppColors.softGreen : AppColors.mocha,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady
                      ? 'Order ${order.id} is ready!'
                      : 'Order ${order.id} · ${order.status.label}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  isReady
                      ? 'Collect at the counter'
                      : '${order.ordersAhead} ahead · ~$wait min (simulated)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
