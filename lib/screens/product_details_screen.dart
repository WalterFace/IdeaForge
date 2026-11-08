import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/content_frame.dart';
import '../widgets/product_art.dart';
import 'cart_screen.dart';

/// Opens the product customization sheet.
Future<void> showProductDetails(
  BuildContext context,
  MenuItem item, {
  bool rushContext = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => ProductDetailsSheet(item: item, rushContext: rushContext),
  );
}

class ProductDetailsSheet extends StatefulWidget {
  const ProductDetailsSheet({
    super.key,
    required this.item,
    this.rushContext = false,
  });

  final MenuItem item;
  final bool rushContext;

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  String? _size;
  String? _milk;
  final Set<AddOn> _addOns = {};
  int _quantity = 1;

  MenuItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    if (item.sizes.isNotEmpty) {
      _size = item.sizes.length > 1 ? item.sizes[1] : item.sizes.first;
      if (!item.sizes.contains(_size)) _size = item.sizes.first;
    }
    if (item.milks.isNotEmpty) _milk = item.milks.first;
  }

  double get _unitPrice =>
      item.priceFor(size: _size, selectedAddOns: _addOns.toList());

  void _add({bool goToCart = false}) {
    final state = AppStateScope.read(context);
    state.addToCart(
      item,
      size: _size,
      milk: _milk,
      addOns: _addOns.toList(),
      quantity: _quantity,
    );
    Navigator.of(context).pop();
    if (goToCart) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CartScreen()),
      );
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$_quantity× ${item.name} added to cart',
            ),
            action: SnackBarAction(
              label: 'View cart',
              textColor: AppColors.caramel,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CartScreen()),
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = AppStateScope.of(context);
    final estimate = state.queueDelayMinutes + item.prepMinutes;

    return ContentFrame(
      maxWidth: 640,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.warmGrayDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, c) => ProductArtView(
                      art: item.art,
                      size: c.maxWidth,
                      radius: 24,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.name,
                            style: theme.textTheme.headlineSmall),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatAed(item.price),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: AppColors.mocha),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill(
                        label: '~${item.prepMinutes} min prep',
                        icon: Icons.timer_outlined,
                      ),
                      Pill(
                        label: '~$estimate min incl. queue (simulated)',
                        icon: Icons.people_alt_outlined,
                        color: widget.rushContext
                            ? AppColors.caramel.withValues(alpha: 0.3)
                            : AppColors.warmGray,
                      ),
                      for (final t in item.tags) Pill(label: t),
                    ],
                  ),
                  if (item.sizes.isNotEmpty) ...[
                    _OptionTitle('Size'),
                    _ChoiceRow(
                      options: item.sizes,
                      selected: _size,
                      labelFor: (s) {
                        final up = item.sizeUpcharge[s] ?? 0;
                        return up == 0 ? s : '$s +${up.toStringAsFixed(0)}';
                      },
                      onSelected: (s) => setState(() => _size = s),
                    ),
                  ],
                  if (item.milks.isNotEmpty) ...[
                    _OptionTitle('Milk'),
                    _ChoiceRow(
                      options: item.milks,
                      selected: _milk,
                      labelFor: (m) => m,
                      onSelected: (m) => setState(() => _milk = m),
                    ),
                  ],
                  if (item.addOns.isNotEmpty) ...[
                    _OptionTitle('Add-ons'),
                    for (final a in item.addOns)
                      CheckboxListTile(
                        value: _addOns.contains(a),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _addOns.add(a);
                          } else {
                            _addOns.remove(a);
                          }
                        }),
                        title: Text(a.name,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        secondary: Text(
                          a.price == 0 ? 'Free' : '+${formatAed(a.price)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.espresso,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Quantity', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      QuantityStepper(
                        value: _quantity,
                        onChanged: (v) => setState(() => _quantity = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.oatCream,
                border: Border(
                  top: BorderSide(color: AppColors.warmGrayDark.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Add · ${formatAed(_unitPrice * _quantity)}',
                      icon: Icons.add_shopping_cart_rounded,
                      onPressed: _add,
                    ),
                  ),
                  if (widget.rushContext) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Add & checkout',
                        style: AppButtonStyle.caramel,
                        onPressed: () => _add(goToCart: true),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTitle extends StatelessWidget {
  const _OptionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final String Function(String) labelFor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(labelFor(o)),
            selected: selected == o,
            onSelected: (_) => onSelected(o),
          ),
      ],
    );
  }
}
