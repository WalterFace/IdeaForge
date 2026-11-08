import 'package:flutter/material.dart';

enum EventCategory {
  tech('Tech', Icons.memory_rounded),
  arts('Arts & Culture', Icons.palette_rounded),
  sports('Sports', Icons.sports_basketball_rounded),
  social('Social', Icons.groups_rounded),
  academic('Academic', Icons.school_rounded);

  const EventCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum RsvpStatus {
  none('Not responded'),
  going('Going'),
  notGoing('Not going');

  const RsvpStatus(this.label);
  final String label;
}

/// Sample campus event (demo content, not a confirmed university event).
class ClubEvent {
  const ClubEvent({
    required this.id,
    required this.title,
    required this.club,
    required this.date,
    required this.time,
    required this.venue,
    required this.description,
    required this.category,
    this.perk,
  });

  final String id;
  final String title;
  final String club;
  final DateTime date;
  final String time;
  final String venue;
  final String description;
  final EventCategory category;

  /// Optional cafe tie-in shown on the card.
  final String? perk;
}
