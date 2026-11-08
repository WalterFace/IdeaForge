import 'package:flutter/material.dart';

import '../models/cafe_order.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/content_frame.dart';
import '../widgets/section_header.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  FulfillmentType _fulfillment = FulfillmentType.takeaway;
  PaymentMethod _payment = PaymentMethod.demoCard;
  final _tableController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final state = AppStateScope.read(context);
    setState(() => _error = null);
    if (_fulfillment == FulfillmentType.atTable &&
        _tableController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your table number.');
      return;
    }
    try {
      final order = await state.placeOrder(
        paymentMethod: _payment,
        fulfillment: _fulfillment,
        tableNumber: _tableController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _OrderPlacedDialog(order: order),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ContentFrame(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text('How would you like it?',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final f in FulfillmentType.values) ...[
                        Expanded(
                          child: _OptionCard(
                            selected: _fulfillment == f,
                            icon: f == FulfillmentType.takeaway
                                ? Icons.shopping_bag_rounded
                                : Icons.table_restaurant_rounded,
                            title: f.label,
                            subtitle: f == FulfillmentType.takeaway
                                ? 'Grab from the counter'
                                : 'We bring it to you',
                            onTap: () => setState(() => _fulfillment = f),
                          ),
                        ),
                        if (f != FulfillmentType.values.last)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: _fulfillment == FulfillmentType.atTable
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextField(
                              controller: _tableController,
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                              decoration: const InputDecoration(
                                labelText: 'Table number',
                                hintText: 'e.g. 12',
                                prefixIcon: Icon(Icons.pin_outlined),
                                counterText: '',
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 24),
                  Text('Payment', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const DemoLabel(
                    'No real payment is processed. No card numbers, CVV or PINs are ever requested in this prototype.',
                  ),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    selected: _payment == PaymentMethod.demoCard,
                    icon: Icons.credit_card_rounded,
                    title: 'Demo Card Payment',
                    badge: 'SIMULATED',
                    subtitle:
                        'Simulated authorization through the mock POS adapter.',
                    onTap: () =>
                        setState(() => _payment = PaymentMethod.demoCard),
                  ),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    selected: _payment == PaymentMethod.payAtCounter,
                    icon: Icons.point_of_sale_rounded,
                    title: 'Pay at Counter',
                    badge: 'DEMO',
                    subtitle: 'Demo selection. Settle with the barista on pickup.',
                    onTap: () =>
                        setState(() => _payment = PaymentMethod.payAtCounter),
                  ),
                  const SizedBox(height: 24),
                  Text('Order summary', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SurfaceCard(
                    child: Column(
                      children: [
                        for (final line in state.cart)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${line.quantity}×',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(line.name,
                                          style: theme.textTheme.bodyLarge),
                                      if (line.customizationSummary.isNotEmpty)
                                        Text(line.customizationSummary,
                                            style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                Text(formatAed(line.lineTotal),
                                    style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          ),
                        const Divider(height: 20),
                        _SummaryRow('Subtotal', formatAed(state.subtotal)),
                        if (state.couponDiscount > 0)
                          _SummaryRow(
                            'Coupon ${state.appliedCoupon}',
                            '-${formatAed(state.couponDiscount)}',
                            color: AppColors.softGreen,
                          ),
                        if (state.rewardDiscount > 0)
                          _SummaryRow(
                            'Reward',
                            '-${formatAed(state.rewardDiscount)}',
                            color: AppColors.softGreen,
                          ),
                        const SizedBox(height: 4),
                        _SummaryRow('Total', formatAed(state.total),
                            strong: true),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Earns ~${(state.total * 10).round()} points when collected',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.softGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_error!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: state.cart.isEmpty
                      ? 'Cart is empty'
                      : 'Place Demo Order · ${formatAed(state.total)}',
                  icon: Icons.check_circle_outline_rounded,
                  loading: state.isPlacingOrder,
                  onPressed: state.cart.isEmpty ? null : _placeOrder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.strong = false, this.color});

  final String label;
  final String value;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style:
                  strong ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: (strong ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      color: selected ? AppColors.espresso : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: selected ? AppColors.caramel : AppColors.mocha),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.oatCream : AppColors.espresso,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? AppColors.oatCream.withValues(alpha: 0.75)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String badge;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: onTap,
      border: Border.all(
        color: selected ? AppColors.caramel : Colors.transparent,
        width: 2,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mocha),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Pill(
                      label: badge,
                      color: AppColors.caramel.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? AppColors.caramel : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _OrderPlacedDialog extends StatelessWidget {
  const _OrderPlacedDialog({required this.order});

  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            Text('Order placed!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              order.id,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.caramel,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Queue position',
                      value: '#${order.queuePosition}',
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.warmGrayDark),
                  Expanded(
                    child: _Stat(
                      label: 'Ahead of you',
                      value: '${order.ordersAhead}',
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.warmGrayDark),
                  Expanded(
                    child: _Stat(
                      label: 'Total',
                      value: formatAed(order.total),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Simulated queue · ${order.paymentMethod.label}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Track my order',
              icon: Icons.receipt_long_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.espresso,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
