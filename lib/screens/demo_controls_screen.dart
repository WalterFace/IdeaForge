import 'package:flutter/material.dart';

import '../models/cafe_order.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/content_frame.dart';
import '../widgets/section_header.dart';

/// Judge-facing controls. Visually distinct from customer screens.
class DemoControlsScreen extends StatelessWidget {
  const DemoControlsScreen({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final active = state.activeOrder;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1512),
        foregroundColor: AppColors.oatCream,
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.caramel),
            SizedBox(width: 10),
            Text('Demo Controls', style: TextStyle(color: AppColors.oatCream)),
          ],
        ),
      ),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.caramel.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.caramel.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, color: AppColors.caramel),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For judges and presenters. These controls simulate what the cafe POS would do in production.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.oatCream),
                    ),
                  ),
                ],
              ),
            ),
            _DarkSection(
              title: 'Active order',
              subtitle: active == null
                  ? 'No active order'
                  : '${active.id} · ${active.status.label}',
              children: [
                if (active == null)
                  AppButton(
                    label: 'Generate sample active order',
                    icon: Icons.add_circle_outline_rounded,
                    style: AppButtonStyle.caramel,
                    onPressed: () {
                      final o = state.generateSampleActiveOrder();
                      _toast(context, 'Created sample order ${o.id}');
                    },
                  )
                else ...[
                  _StatusButton(
                    label: 'Move to Preparing',
                    icon: Icons.coffee_maker_rounded,
                    enabled: active.status.index < OrderStatus.preparing.index,
                    onPressed: () {
                      state.setOrderStatus(active.id, OrderStatus.preparing);
                      _toast(context, '${active.id} is now Preparing');
                    },
                  ),
                  const SizedBox(height: 8),
                  _StatusButton(
                    label: 'Mark Ready',
                    icon: Icons.notifications_active_rounded,
                    enabled: active.status.index < OrderStatus.ready.index,
                    onPressed: () {
                      state.setOrderStatus(active.id, OrderStatus.ready);
                      _toast(context,
                          '${active.id} is Ready. Check the Orders tab!');
                    },
                  ),
                  const SizedBox(height: 8),
                  _StatusButton(
                    label: 'Mark Collected (awards points once)',
                    icon: Icons.check_circle_rounded,
                    enabled: active.status.index < OrderStatus.collected.index,
                    onPressed: () {
                      state.setOrderStatus(active.id, OrderStatus.collected);
                      _toast(context,
                          '${active.id} collected. +${(active.total * 10).round()} points');
                    },
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Generate another sample order',
                    icon: Icons.add_circle_outline_rounded,
                    style: AppButtonStyle.ghost,
                    onPressed: () {
                      final o = state.generateSampleActiveOrder();
                      _toast(context, 'Created sample order ${o.id}');
                    },
                  ),
                ],
                const SizedBox(height: 8),
                AppButton(
                  label: 'Open Orders tab',
                  icon: Icons.receipt_long_rounded,
                  style: AppButtonStyle.secondary,
                  onPressed: () {
                    state.setTab(2);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ],
            ),
            _DarkSection(
              title: 'Sample data',
              subtitle:
                  'Loyalty: ${state.loyalty.lifetimePoints} lifetime · ${state.loyalty.spendablePoints} spendable',
              children: [
                AppButton(
                  label: 'Restore initial loyalty state',
                  icon: Icons.restore_rounded,
                  style: AppButtonStyle.ghost,
                  onPressed: () {
                    state.restoreInitialLoyalty();
                    _toast(context, 'Loyalty restored to Gold · 1,240 pts');
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Reset sample data (keep nickname)',
                  icon: Icons.refresh_rounded,
                  style: AppButtonStyle.ghost,
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      'Reset sample data?',
                      'Clears cart, demo orders, RSVPs and points activity. Seeded history is restored.',
                    );
                    if (!context.mounted || !ok) return;
                    state.resetDemoData();
                    _toast(context, 'Sample data reset');
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Reset demo (show welcome again)',
                  icon: Icons.power_settings_new_rounded,
                  style: AppButtonStyle.secondary,
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      'Full reset?',
                      'Everything returns to first launch, including the nickname.',
                    );
                    if (!context.mounted || !ok) return;
                    await state.resetEverything();
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ],
            ),
            _DarkSection(
              title: 'About the prototype',
              subtitle: 'ideaForge × AIRC · Altitude Cafe · RIT Dubai',
              children: [
                const _AboutRow(
                  icon: Icons.phone_android_rounded,
                  color: AppColors.softGreen,
                  title: 'Runs fully on-device',
                  text:
                      'Menu, cart, ordering, Rush Mode with walk-time and busy-hour awareness, scheduled pickup, Green Cup, streaks and challenges, pay-it-forward gift codes, loyalty, events and RSVPs all work offline. State is saved locally and survives refresh/restart.',
                ),
                const _AboutRow(
                  icon: Icons.science_outlined,
                  color: AppColors.caramel,
                  title: 'Simulated',
                  text:
                      'Queue positions, busy-hour levels, wait estimates, walk times, order status changes, card payment authorization and the POS itself (MockPosGateway). Gift codes are redeemed on this device only. Nothing here reflects live cafe data.',
                ),
                const _AboutRow(
                  icon: Icons.link_rounded,
                  color: AppColors.info,
                  title: 'Needs real cafe integration',
                  text:
                      'MOBIPOS order creation and status sync, an approved payment provider, push notifications, menu/price sync and staff-side order management. The PosGateway interface is the swap point.',
                ),
                const _AboutRow(
                  icon: Icons.rocket_launch_rounded,
                  color: AppColors.latte,
                  title: 'Planned for production',
                  text:
                      'Vendor-approved MOBIPOS adapter, real auth for students, payment reconciliation, idempotent order submission, analytics on popular items, and a club-event submission flow via Student Life.',
                ),
                const SizedBox(height: 10),
                Text(
                  'Adapter in use: ${state.posGateway.displayName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.oatCream.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _DarkSection extends StatelessWidget {
  const _DarkSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A211C),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.oatCream,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.oatCream.withValues(alpha: 0.6),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: enabled ? label : '$label ✓',
      icon: icon,
      style: enabled ? AppButtonStyle.caramel : AppButtonStyle.ghost,
      onPressed: enabled ? onPressed : null,
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.oatCream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    color: AppColors.oatCream.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Re-exported so Home can show a one-tap link without importing the shell.
class DemoControlsEntry extends StatelessWidget {
  const DemoControlsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Demo Controls',
      actionLabel: 'Open',
      onAction: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DemoControlsScreen()),
      ),
    );
  }
}
