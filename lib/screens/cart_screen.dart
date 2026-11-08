import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../models/cart_line.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/content_frame.dart';
import '../widgets/product_art.dart';
import '../widgets/section_header.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  String? _couponMessage;
  bool _couponError = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final state = AppStateScope.read(context);
    final result = state.applyCoupon(_couponController.text);
    setState(() {
      switch (result) {
        case CouponResult.applied:
          _couponMessage = 'CAMPUS10 applied. 10% off!';
          _couponError = false;
          _couponController.clear();
        case CouponResult.alreadyApplied:
          _couponMessage = 'That coupon is already applied.';
          _couponError = true;
        case CouponResult.invalid:
          _couponMessage = 'Unknown code. Try CAMPUS10.';
          _couponError = true;
        case CouponResult.emptyCart:
          _couponMessage = 'Add something to the cart first.';
          _couponError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final lines = state.cart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (lines.isNotEmpty)
            TextButton(
              onPressed: () {
                state.clearCart();
                setState(() => _couponMessage = null);
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: ContentFrame(
        child: lines.isEmpty
            ? EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Browse the menu or let Rush Mode pick for you.',
                action: AppButton(
                  label: 'Browse menu',
                  expanded: false,
                  onPressed: () {
                    state.setTab(1);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        for (final line in lines) ...[
                          _CartLineTile(line: line),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        Text('Coupon', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (state.appliedCoupon != null)
                          SurfaceCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            color: AppColors.softGreen.withValues(alpha: 0.12),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.softGreen),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${state.appliedCoupon} · ${SeedData.campusCoupon.percentOff}% off applied',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    state.removeCoupon();
                                    setState(() => _couponMessage = null);
                                  },
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  onSubmitted: (_) => _applyCoupon(),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter code (try CAMPUS10)',
                                    prefixIcon: Icon(
                                        Icons.confirmation_number_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              AppButton(
                                label: 'Apply',
                                expanded: false,
                                onPressed: _applyCoupon,
                              ),
                            ],
                          ),
                        if (_couponMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _couponMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _couponError
                                  ? AppColors.danger
                                  : AppColors.softGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _RewardSection(),
                      ],
                    ),
                  ),
                  _CartSummary(
                    onCheckout: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.read(context);
    final theme = Theme.of(context);
    final item = state.itemById(line.itemId);
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ProductArtView(art: item.art, size: 64, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: theme.textTheme.titleSmall),
                if (line.customizationSummary.isNotEmpty)
                  Text(
                    line.customizationSummary,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    QuantityStepper(
                      value: line.quantity,
                      compact: true,
                      onChanged: (v) => state.setLineQuantity(line.id, v),
                    ),
                    const Spacer(),
                    Text(
                      formatAed(line.lineTotal),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: AppColors.mocha),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => state.removeLine(line.id),
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RewardSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final pending = state.pendingReward;
    final affordable = state.rewards
        .where((r) => r.pointsCost <= state.loyalty.spendablePoints)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Use rewards', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text(
              '${formatPoints(state.loyalty.spendablePoints)} pts available',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pending != null)
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.caramel.withValues(alpha: 0.18),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.caramel),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pending.title} · ${pending.pointsCost} pts will be redeemed',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: state.removeReward,
                  child: const Text('Remove'),
                ),
              ],
            ),
          )
        else if (affordable.isEmpty)
          Text(
            'Earn more points to unlock rewards (100 pts = AED 5).',
            style: theme.textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in affordable)
                ActionChip(
                  avatar: const Icon(Icons.stars_rounded,
                      size: 16, color: AppColors.caramel),
                  label: Text('${r.title} · ${r.pointsCost} pts'),
                  onPressed: () {
                    final res = state.applyReward(r);
                    if (res != RewardResult.applied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not apply that reward.')),
                      );
                    }
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    Widget row(String label, String value,
            {bool strong = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Text(label,
                  style: strong
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                value,
                style: (strong
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('Subtotal', formatAed(state.subtotal)),
            if (state.couponDiscount > 0)
              row('Coupon (${state.appliedCoupon})',
                  '-${formatAed(state.couponDiscount)}',
                  color: AppColors.softGreen),
            if (state.rewardDiscount > 0)
              row('Reward', '-${formatAed(state.rewardDiscount)}',
                  color: AppColors.softGreen),
            const Divider(height: 16),
            row('Total', formatAed(state.total), strong: true),
            const SizedBox(height: 12),
            AppButton(
              label: 'Checkout',
              icon: Icons.arrow_forward_rounded,
              onPressed: onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}
