import 'package:flutter/material.dart';

import '../screens/campus_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/demo_controls_screen.dart';
import '../screens/home_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/rewards_screen.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import 'content_frame.dart';

/// Root scaffold: app bar with cart badge, five-tab bottom navigation and the
/// in-app "order ready" alert.
class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key});

  static const List<String> _titles = [
    'ALTITUDE',
    'Menu',
    'Orders',
    'Rewards',
    'Campus',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final index = state.tabIndex;
    final ready = state.orderAwaitingPickup;

    return Scaffold(
      appBar: AppBar(
        title: index == 0 ? const _BrandTitle() : Text(_titles[index]),
        actions: [
          IconButton(
            tooltip: 'Demo Controls',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DemoControlsScreen(),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
          CartIconButton(count: state.cartCount),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: ready == null
                ? const SizedBox(width: double.infinity)
                : ContentFrame(
                    child: ReadyBanner(
                      orderId: ready.id,
                      onView: () => state.setTab(2),
                      onDismiss: () => state.dismissReadyAlert(ready.id),
                    ),
                  ),
          ),
          Expanded(
            child: ContentFrame(
              child: IndexedStack(
                index: index,
                children: const [
                  HomeScreen(),
                  MenuScreen(),
                  OrdersScreen(),
                  RewardsScreen(),
                  CampusScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: state.setTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: state.activeOrders.isNotEmpty,
              backgroundColor: AppColors.caramel,
              smallSize: 8,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: state.activeOrders.isNotEmpty,
              backgroundColor: AppColors.caramel,
              smallSize: 8,
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars_rounded),
            label: 'Rewards',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Campus',
          ),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.espressoGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.terrain_rounded,
              color: AppColors.caramel, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'ALTITUDE',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            color: AppColors.espresso,
          ),
        ),
      ],
    );
  }
}

/// Cart icon with a quantity badge. Opens the cart screen.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CartScreen()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.caramel,
        textColor: AppColors.espresso,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

/// Prominent in-app alert shown when an order is ready.
class ReadyBanner extends StatelessWidget {
  const ReadyBanner({
    super.key,
    required this.orderId,
    required this.onView,
    required this.onDismiss,
  });

  final String orderId;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your order is ready for pickup!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$orderId · collect at the Altitude counter',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
