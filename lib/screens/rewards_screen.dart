import 'package:flutter/material.dart';

import '../models/loyalty_account.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/section_header.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final account = state.loyalty;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: LoyaltyCard(account: account, nickname: state.nickname),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Tier',
                  value: account.tier.label,
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.caramel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Lifetime pts',
                  value: formatPoints(account.lifetimePoints),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.mocha,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'To spend',
                  value: formatPoints(account.spendablePoints),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.softGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SurfaceCard(
            color: AppColors.warmGray,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.mocha),
                    const SizedBox(width: 8),
                    Text('How points work', style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Earn 10 points for every AED 1 spent, on the post-discount total, rounded to the nearest point.\n'
                  '• Points are added once, when your order is marked Collected.\n'
                  '• Lifetime points set your tier (Silver 500 · Gold 1,000 · Platinum 1,500) and never go down.\n'
                  '• Spendable points are a separate balance you redeem for rewards.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SectionHeader(
          title: 'Rewards',
          subtitle: 'Apply one reward per order at checkout',
        ),
        for (final r in state.rewards)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _RewardTile(reward: r),
          ),
        const SectionHeader(
          title: 'Activity',
          subtitle: 'Recent points earned and redeemed',
        ),
        if (account.activity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('No activity yet.', style: theme.textTheme.bodyMedium),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < account.activity.length; i++) ...[
                    _ActivityRow(activity: account.activity[i], now: now),
                    if (i < account.activity.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.espresso,
              ),
            ),
          ),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward});

  final RewardOption reward;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final affordable = state.loyalty.spendablePoints >= reward.pointsCost;
    final isPending = state.pendingReward?.id == reward.id;
    final cartEmpty = state.cart.isEmpty;

    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.caramelGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${reward.pointsCost}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.espresso,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(reward.description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isPending)
            const Pill(
              label: 'IN CART',
              color: AppColors.softGreen,
              textColor: Colors.white,
            )
          else
            AppButton(
              label: cartEmpty ? 'Add items' : 'Redeem',
              expanded: false,
              dense: true,
              style: AppButtonStyle.secondary,
              onPressed: !affordable
                  ? null
                  : cartEmpty
                      ? () => state.setTab(1)
                      : () {
                          final res = state.applyReward(reward);
                          final msg = switch (res) {
                            RewardResult.applied =>
                              '${reward.title} will be applied at checkout.',
                            RewardResult.alreadyApplied =>
                              'A reward is already applied to this cart.',
                            RewardResult.insufficientPoints =>
                              'Not enough points yet.',
                            RewardResult.emptyCart =>
                              'Add something to the cart first.',
                          };
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(content: Text(msg)));
                        },
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.now});

  final LoyaltyActivity activity;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = activity.pointsDelta > 0;
    final neutral = activity.pointsDelta == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: neutral
                  ? AppColors.caramel.withValues(alpha: 0.2)
                  : positive
                      ? AppColors.softGreen.withValues(alpha: 0.15)
                      : AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              neutral
                  ? Icons.workspace_premium_rounded
                  : positive
                      ? Icons.add_rounded
                      : Icons.redeem_rounded,
              size: 18,
              color: neutral
                  ? AppColors.caramel
                  : positive
                      ? AppColors.softGreen
                      : AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(formatRelative(activity.timestamp, now),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            neutral
                ? ''
                : '${positive ? '+' : ''}${formatPoints(activity.pointsDelta)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: positive ? AppColors.softGreen : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
