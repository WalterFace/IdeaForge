import 'package:flutter/material.dart';

import '../models/loyalty_account.dart';
import '../models/menu_item.dart';
import '../services/challenges_engine.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/product_art.dart';
import '../widgets/section_header.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final account = state.loyalty;
    final now = state.now;
    final challenges = state.challenges;
    final claimable = challenges.where((c) => c.claimable).length;

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
                  label: 'Streak',
                  value:
                      '${state.streakDays} day${state.streakDays == 1 ? '' : 's'}',
                  icon: Icons.local_fire_department_rounded,
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
                  label: 'Cups saved',
                  value: '${state.cupsSaved}',
                  icon: Icons.eco_rounded,
                  color: AppColors.softGreen,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Weekly challenges',
          subtitle: claimable > 0
              ? '$claimable bonus${claimable == 1 ? '' : 'es'} ready to claim'
              : 'Computed from your order history',
        ),
        for (final c in challenges)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _ChallengeTile(challenge: c),
          ),
        const SectionHeader(
          title: 'Green Cup',
          subtitle: 'Bring a reusable cup, save money, earn more',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SurfaceCard(
            gradient: AppColors.greenGradient,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.cupsSaved} cup${state.cupsSaved == 1 ? '' : 's'} saved · ~${(state.cupsSaved * 12)} g of plastic',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toggle "bringing my own cup" at checkout: AED ${AppState.greenCupDiscountPerDrink.toStringAsFixed(0)} off every drink and +${AppState.greenCupBonusPoints} points when collected. Plastic figure is a rough demo estimate.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionHeader(
          title: 'Pay it forward',
          subtitle:
              '${state.kindnessCount} coffees gifted on campus this month (sample)',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PayItForwardCard(),
        ),
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
                  '• Challenge bonuses and Green Cup bonuses are added on top.\n'
                  '• Lifetime points set your tier (Silver 500 · Gold 1,000 · Platinum 1,500) and never go down.\n'
                  '• Spendable points are a separate balance you redeem for rewards or gifts.',
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

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge});

  final ChallengeProgress challenge;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.read(context);
    final theme = Theme.of(context);
    final c = challenge;
    final color = c.claimed
        ? AppColors.textMuted
        : c.completed
            ? AppColors.softGreen
            : AppColors.caramel;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      border: c.claimable
          ? Border.all(color: AppColors.softGreen, width: 1.5)
          : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(c.icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.title, style: theme.textTheme.titleSmall),
                    ),
                    Text(
                      '+${c.bonusPoints} pts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Text(c.description, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: c.fraction,
                          minHeight: 6,
                          backgroundColor: AppColors.warmGray,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${c.progress.clamp(0, c.target)}/${c.target}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (c.claimable) ...[
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Claim +${c.bonusPoints} points',
                    icon: Icons.redeem_rounded,
                    style: AppButtonStyle.green,
                    dense: true,
                    onPressed: () {
                      state.claimChallenge(c.id);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(
                            content: Text(
                                '${c.title} complete! +${c.bonusPoints} points')));
                    },
                  ),
                ] else if (c.claimed) ...[
                  const SizedBox(height: 6),
                  Text('Claimed',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayItForwardCard extends StatelessWidget {
  static const List<String> _giftableIds = [
    'karak_chai',
    'americano',
    'iced_latte',
    'caramel_cloud_latte',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final recent = state.giftVouchers.take(3).toList();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded,
                  color: AppColors.caramel),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Gift a coffee with points',
                    style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a drink, we generate a code you can share. Whoever enters it in their cart gets the drink free. In this demo the code is redeemed on this device.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _giftableIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = state.itemById(_giftableIds[i]);
                final size = item.sizes.isEmpty ? null : item.sizes.first;
                final cost = state.giftCostPoints(item, size: size);
                final affordable = state.loyalty.spendablePoints >= cost;
                return _GiftOption(
                  item: item,
                  cost: cost,
                  affordable: affordable,
                  onTap: () => _gift(context, item, size),
                );
              },
            ),
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Your gift codes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final g in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      g.isRedeemed
                          ? Icons.check_circle_rounded
                          : Icons.confirmation_number_outlined,
                      size: 16,
                      color: g.isRedeemed
                          ? AppColors.softGreen
                          : AppColors.caramel,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${g.code} · ${state.itemById(g.itemId).name}'
                        '${g.isRedeemed ? ' · redeemed' : ' · share it!'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: g.isRedeemed
                              ? AppColors.textMuted
                              : AppColors.espresso,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _gift(BuildContext context, MenuItem item, String? size) {
    final state = AppStateScope.read(context);
    final voucher = state.giftCoffee(item, size: size);
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    if (voucher == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Not enough points for that gift yet.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gift created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A ${item.name} is waiting for someone. Share this code:'),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.espresso,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  voucher.code,
                  style: const TextStyle(
                    color: AppColors.caramel,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Demo: enter it under "Got a gift code?" in the cart to redeem it.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _GiftOption extends StatelessWidget {
  const _GiftOption({
    required this.item,
    required this.cost,
    required this.affordable,
    required this.onTap,
  });

  final MenuItem item;
  final int cost;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 124,
      child: Opacity(
        opacity: affordable ? 1 : 0.5,
        child: SurfaceCard(
          padding: const EdgeInsets.all(10),
          color: AppColors.oatCream,
          onTap: affordable ? onTap : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductArtView(art: item.art, size: 104, radius: 14),
              const SizedBox(height: 6),
              Text(item.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espresso,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('$cost pts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.caramel,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
        ),
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
