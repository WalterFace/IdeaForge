import 'package:flutter/material.dart';

import '../models/club_event.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/section_header.dart';

class CampusScreen extends StatelessWidget {
  const CampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final events = state.events;
    final going = events.where((e) => state.rsvpFor(e.id) == RsvpStatus.going).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: SurfaceCard(
            gradient: AppColors.greenGradient,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clubs & Events',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        going == 0
                            ? 'RSVP to what\'s happening around campus this fortnight.'
                            : 'You\'re going to $going event${going == 1 ? '' : 's'}. See you there!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.celebration_rounded,
                    size: 48, color: Colors.white.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: DemoLabel(
            'Sample events for the prototype. These are not confirmed RIT Dubai events.',
          ),
        ),
        const SectionHeader(title: 'Upcoming', subtitle: 'Sorted by date'),
        for (final e in events)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: _EventCard(event: e),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Clubs: want your event here? In a production rollout, club leads would submit events through Student Life for approval.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final ClubEvent event;

  Color get _accent => switch (event.category) {
        EventCategory.tech => AppColors.info,
        EventCategory.arts => const Color(0xFFB0577A),
        EventCategory.sports => const Color(0xFFCB6F3B),
        EventCategory.social => AppColors.caramel,
        EventCategory.academic => AppColors.softGreen,
      };

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final rsvp = state.rsvpFor(event.id);

    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${event.date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _accent,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatShortDate(event.date).split(', ').first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill(
                        label: event.category.label,
                        icon: event.category.icon,
                        color: _accent,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(event.title, style: theme.textTheme.titleMedium),
                      Text(event.club, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${formatShortDate(event.date)} · ${event.time}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(event.venue, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(event.description, style: theme.textTheme.bodyMedium),
                if (event.perk != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.local_cafe_rounded,
                          size: 16, color: AppColors.caramel),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.perk!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mocha,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: rsvp == RsvpStatus.going ? 'Going ✓' : 'Going',
                        icon: Icons.check_rounded,
                        dense: true,
                        style: rsvp == RsvpStatus.going
                            ? AppButtonStyle.green
                            : AppButtonStyle.secondary,
                        onPressed: () => state.setRsvp(
                          event.id,
                          rsvp == RsvpStatus.going
                              ? RsvpStatus.none
                              : RsvpStatus.going,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: rsvp == RsvpStatus.notGoing
                            ? 'Not going ✓'
                            : 'Not going',
                        icon: Icons.close_rounded,
                        dense: true,
                        style: rsvp == RsvpStatus.notGoing
                            ? AppButtonStyle.primary
                            : AppButtonStyle.ghost,
                        onPressed: () => state.setRsvp(
                          event.id,
                          rsvp == RsvpStatus.notGoing
                              ? RsvpStatus.none
                              : RsvpStatus.notGoing,
                        ),
                      ),
                    ),
                  ],
                ),
                if (rsvp != RsvpStatus.none) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Your RSVP: ${rsvp.label} (saved on this device)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: rsvp == RsvpStatus.going
                          ? AppColors.softGreen
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
