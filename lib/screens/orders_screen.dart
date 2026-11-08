import 'package:flutter/material.dart';

import '../models/cafe_order.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/product_art.dart';
import '../widgets/section_header.dart';
import 'cart_screen.dart';
import 'demo_controls_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final active = state.activeOrders;
    final past = state.pastOrders;

    if (active.isEmpty && past.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Place a demo order from the menu or Rush Mode.',
        action: AppButton(
          label: 'Browse menu',
          expanded: false,
          onPressed: () => state.setTab(1),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (active.isNotEmpty) ...[
          const SectionHeader(
            title: 'Active orders',
            subtitle: 'Queue and wait times are simulated',
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
          ),
          for (final o in active)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _ActiveOrderCard(order: o),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: SurfaceCard(
              color: AppColors.warmGray,
              child: Row(
                children: [
                  const Icon(Icons.coffee_outlined, color: AppColors.mocha),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No active order. Reorder a favourite below or visit the menu.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (past.isNotEmpty) ...[
          SectionHeader(
            title: 'Order history',
            subtitle:
                '${past.length} collected order${past.length == 1 ? '' : 's'}',
          ),
          for (final o in past)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _PastOrderCard(order: o),
            ),
        ],
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final isReady = order.status == OrderStatus.ready;
    final wait = order.estimatedWaitMinutes(state.prepMinutesFor);

    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReady)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your order is ready for pickup!',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ${order.id}',
                              style: theme.textTheme.titleLarge),
                          Text(
                            '${order.fulfillment.label}'
                            '${order.tableNumber != null ? ' · Table ${order.tableNumber}' : ''}'
                            ' · ${formatTime(order.createdAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Pill(
                      label: order.status.label.toUpperCase(),
                      color: isReady ? AppColors.softGreen : AppColors.caramel,
                      textColor: isReady ? Colors.white : AppColors.espresso,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _QueueStat(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Queue position',
                        value: '#${order.queuePosition}',
                      ),
                    ),
                    Expanded(
                      child: _QueueStat(
                        icon: Icons.people_alt_outlined,
                        label: 'Orders ahead',
                        value: '${order.ordersAhead}',
                      ),
                    ),
                    Expanded(
                      child: _QueueStat(
                        icon: Icons.timer_outlined,
                        label: 'Est. wait',
                        value: isReady ? 'Now' : '~$wait min',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const DemoLabel('Simulated queue. Not connected to the cafe.'),
                const SizedBox(height: 18),
                OrderStatusTimeline(
                  status: order.status,
                  timestamps: order.statusTimestamps,
                ),
                const Divider(height: 28),
                for (final line in order.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ProductArtView(
                          art: state.itemById(line.itemId).art,
                          size: 36,
                          radius: 10,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${line.quantity}× ${line.name}',
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              if (line.customizationSummary.isNotEmpty)
                                Text(line.customizationSummary,
                                    style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(formatAed(line.lineTotal),
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Subtotal', style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text(formatAed(order.subtotal),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                if (order.discount > 0 || order.rewardDiscount > 0)
                  Row(
                    children: [
                      Text('Discounts', style: theme.textTheme.bodySmall),
                      const Spacer(),
                      Text(
                        '-${formatAed(order.discount + order.rewardDiscount)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.softGreen),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Text('Total', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(formatAed(order.total),
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: order.status.next == null
                            ? 'Done'
                            : switch (order.status.next!) {
                                OrderStatus.preparing =>
                                  'Demo: start preparing',
                                OrderStatus.ready => 'Demo: mark ready',
                                OrderStatus.collected => 'Demo: mark collected',
                                OrderStatus.received => 'Demo',
                              },
                        icon: Icons.fast_forward_rounded,
                        style: AppButtonStyle.ghost,
                        dense: true,
                        onPressed: order.status.next == null
                            ? null
                            : () => state.advanceOrder(order.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Demo Controls',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DemoControlsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded),
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

class _QueueStat extends StatelessWidget {
  const _QueueStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.mocha),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.espresso,
          ),
        ),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _PastOrderCard extends StatelessWidget {
  const _PastOrderCard({required this.order});

  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.read(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.id, style: theme.textTheme.titleSmall),
              ),
              if (order.isSeeded)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Pill(label: 'Sample'),
                ),
              Text(formatRelative(order.createdAt, now),
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.lines.map((l) => '${l.quantity}× ${l.name}').join(', '),
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(formatAed(order.total),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppColors.mocha)),
                    Pill(
                      label: order.pointsAwarded
                          ? '+${(order.total * 10).round()} pts'
                          : 'No points',
                      color: AppColors.softGreen.withValues(alpha: 0.15),
                      textColor: AppColors.softGreen,
                      icon: Icons.stars_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Reorder',
                icon: Icons.replay_rounded,
                expanded: false,
                dense: true,
                style: AppButtonStyle.secondary,
                onPressed: () {
                  state.reorder(order);
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        content:
                            Text('${order.itemCount} item(s) added to cart'),
                        action: SnackBarAction(
                          label: 'View cart',
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
    );
  }
}
