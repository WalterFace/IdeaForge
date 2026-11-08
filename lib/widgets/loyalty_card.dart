import 'package:flutter/material.dart';

import '../models/loyalty_account.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'product_art.dart';

/// Espresso-dark loyalty card with tier progress.
class LoyaltyCard extends StatelessWidget {
  const LoyaltyCard({
    super.key,
    required this.account,
    required this.nickname,
    this.onTap,
  });

  final LoyaltyAccount account;
  final String nickname;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final next = account.nextTier;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppColors.espressoGradient),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: const BeanPatternPainter(opacity: 0.05),
                  ),
                ),
                Positioned(
                  right: -30,
                  top: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.caramel.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALTITUDE REWARDS',
                                  style: TextStyle(
                                    color: AppColors.oatCream
                                        .withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nickname,
                                  style: const TextStyle(
                                    color: AppColors.oatCream,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          _TierBadge(tier: account.tier),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatPoints(account.lifetimePoints),
                            style: const TextStyle(
                              color: AppColors.oatCream,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'lifetime pts',
                              style: TextStyle(
                                color: AppColors.oatCream.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatPoints(account.spendablePoints),
                                style: const TextStyle(
                                  color: AppColors.caramel,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'to spend',
                                style: TextStyle(
                                  color:
                                      AppColors.oatCream.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: account.tierProgress),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor:
                                AppColors.oatCream.withValues(alpha: 0.15),
                            color: AppColors.caramel,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        next == null
                            ? 'Top tier reached. Thank you!'
                            : '${formatPoints(account.pointsToNextTier)} pts to ${next.label}',
                        style: TextStyle(
                          color: AppColors.oatCream.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final LoyaltyTier tier;

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      LoyaltyTier.bronze => const Color(0xFFB87E52),
      LoyaltyTier.silver => const Color(0xFFBFC5CC),
      LoyaltyTier.gold => AppColors.caramel,
      LoyaltyTier.platinum => const Color(0xFFD9E3EC),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 15, color: AppColors.espresso),
          const SizedBox(width: 5),
          Text(
            tier.label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.espresso,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
