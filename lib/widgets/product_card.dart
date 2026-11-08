import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'product_art.dart';

/// Grid card for the menu.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAdd,
    this.badge,
  });

  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: LayoutBuilder(
                  builder: (context, c) => ProductArtView(
                    art: item.art,
                    size: c.maxWidth,
                    radius: 16,
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Pill(
                    label: badge!,
                    color: AppColors.espresso,
                    textColor: AppColors.oatCream,
                  ),
                ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Pill(
                  label: '~${item.prepMinutes} min',
                  color: Colors.white.withValues(alpha: 0.9),
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatAed(item.price),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.mocha,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Material(
                color: AppColors.espresso,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.add_rounded,
                        color: AppColors.oatCream, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal tile for carousels (Popular Picks, Rush Mode).
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.item,
    required this.onTap,
    this.caption,
    this.captionColor,
    this.width = 150,
    this.trailing,
  });

  final MenuItem item;
  final VoidCallback onTap;
  final String? caption;
  final Color? captionColor;
  final double width;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: SurfaceCard(
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ProductArtView(art: item.art, size: width - 20, radius: 14),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    caption ?? formatAed(item.price),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: captionColor ?? AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
