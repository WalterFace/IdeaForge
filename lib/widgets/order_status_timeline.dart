import 'package:flutter/material.dart';

import '../models/cafe_order.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Horizontal Received → Preparing → Ready → Collected timeline.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.status,
    required this.timestamps,
  });

  final OrderStatus status;
  final Map<OrderStatus, DateTime> timestamps;

  static IconData iconFor(OrderStatus s) => switch (s) {
        OrderStatus.received => Icons.receipt_long_rounded,
        OrderStatus.preparing => Icons.coffee_maker_rounded,
        OrderStatus.ready => Icons.notifications_active_rounded,
        OrderStatus.collected => Icons.check_circle_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final steps = OrderStatus.values;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _Step(
              status: steps[i],
              state: steps[i].index < status.index
                  ? _StepState.done
                  : steps[i].index == status.index
                      ? _StepState.current
                      : _StepState.pending,
              time: timestamps[steps[i]],
            ),
          ),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 17),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: steps[i].index < status.index
                      ? AppColors.softGreen
                      : AppColors.warmGrayDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

enum _StepState { done, current, pending }

class _Step extends StatelessWidget {
  const _Step({required this.status, required this.state, this.time});

  final OrderStatus status;
  final _StepState state;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (state) {
      _StepState.done => (AppColors.softGreen, Colors.white),
      _StepState.current => (AppColors.caramel, AppColors.espresso),
      _StepState.pending => (AppColors.warmGray, AppColors.textMuted),
    };
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: state == _StepState.current
                ? [
                    BoxShadow(
                      color: AppColors.caramel.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(OrderStatusTimeline.iconFor(status), size: 18, color: fg),
        ),
        const SizedBox(height: 6),
        Text(
          status.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight:
                state == _StepState.pending ? FontWeight.w500 : FontWeight.w700,
            color: state == _StepState.pending
                ? AppColors.textMuted
                : AppColors.espresso,
          ),
        ),
        if (time != null)
          Text(
            formatTime(time!),
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
      ],
    );
  }
}
