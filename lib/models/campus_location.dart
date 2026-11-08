import 'package:flutter/material.dart';

/// Where the student is on campus. Walk time to the Altitude counter is a
/// fixed demo estimate; no GPS is used or requested.
class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.walkMinutes,
    required this.icon,
  });

  final String id;
  final String name;
  final int walkMinutes;
  final IconData icon;

  static const List<CampusLocation> all = [
    CampusLocation(
      id: 'cafe',
      name: 'At the cafe',
      walkMinutes: 0,
      icon: Icons.local_cafe_rounded,
    ),
    CampusLocation(
      id: 'library',
      name: 'Library',
      walkMinutes: 2,
      icon: Icons.menu_book_rounded,
    ),
    CampusLocation(
      id: 'business',
      name: 'Business block',
      walkMinutes: 3,
      icon: Icons.business_center_rounded,
    ),
    CampusLocation(
      id: 'engineering',
      name: 'Engineering labs',
      walkMinutes: 4,
      icon: Icons.precision_manufacturing_rounded,
    ),
    CampusLocation(
      id: 'sports',
      name: 'Sports hall',
      walkMinutes: 6,
      icon: Icons.sports_basketball_rounded,
    ),
    CampusLocation(
      id: 'dorms',
      name: 'Dorms',
      walkMinutes: 7,
      icon: Icons.apartment_rounded,
    ),
  ];

  static CampusLocation byId(String? id) =>
      all.firstWhere((l) => l.id == id, orElse: () => all.first);
}
