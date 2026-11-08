import 'package:flutter/material.dart';

enum MenuCategory {
  coffee('Coffee', Icons.coffee_rounded),
  iced('Iced', Icons.ac_unit_rounded),
  tea('Tea', Icons.emoji_food_beverage_rounded),
  bakery('Bakery', Icons.bakery_dining_rounded),
  snacks('Snacks', Icons.cookie_rounded);

  const MenuCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Visual style used by the locally-drawn product art.
enum ProductArt { espresso, latte, iced, matcha, tea, pastry, cookie, sandwich }

class AddOn {
  const AddOn(this.name, this.price);
  final String name;
  final double price;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.tags,
    required this.prepMinutes,
    required this.art,
    this.sizes = const [],
    this.sizeUpcharge = const {},
    this.milks = const [],
    this.addOns = const [],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;
  final List<String> tags;

  /// Estimated preparation time in minutes (demo model, not real data).
  final int prepMinutes;
  final ProductArt art;
  final List<String> sizes;
  final Map<String, double> sizeUpcharge;
  final List<String> milks;
  final List<AddOn> addOns;

  bool get hasCustomizations =>
      sizes.isNotEmpty || milks.isNotEmpty || addOns.isNotEmpty;

  double priceFor({String? size, List<AddOn> selectedAddOns = const []}) {
    var total = price;
    if (size != null) total += sizeUpcharge[size] ?? 0;
    for (final a in selectedAddOns) {
      total += a.price;
    }
    return total;
  }
}
