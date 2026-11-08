import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/content_frame.dart';
import '../widgets/product_art.dart';

/// First-launch welcome panel. No login, optional nickname.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    AppStateScope.read(context).completeOnboarding(nickname: _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: BeanPatternPainter(opacity: 0.05)),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.caramel.withValues(alpha: 0.35),
                    AppColors.caramel.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ContentFrame(
              maxWidth: 520,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.caramel,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.terrain_rounded,
                          color: AppColors.espresso, size: 36),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ALTITUDE',
                      style: TextStyle(
                        color: AppColors.oatCream,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your campus, in a cup',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.caramel,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const _Feature(
                      icon: Icons.bolt_rounded,
                      title: 'Rush Mode',
                      text:
                          'Running late? Tell us your time window and we pick what can be ready.',
                    ),
                    const _Feature(
                      icon: Icons.receipt_long_rounded,
                      title: 'Order ahead',
                      text:
                          'Takeaway or at your table, with a live (simulated) queue.',
                    ),
                    const _Feature(
                      icon: Icons.stars_rounded,
                      title: 'Earn rewards',
                      text: '10 points for every AED 1. Gold tier from day one.',
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.oatCream,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('What should we call you?',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Optional. No account or login needed.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 24,
                            onSubmitted: (_) => _start(),
                            decoration: const InputDecoration(
                              hintText: SeedData.defaultNickname,
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Get Started',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _start,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'ideaForge × AIRC · RIT Dubai · offline hackathon prototype',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.oatCream.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.oatCream.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.caramel, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.oatCream,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    color: AppColors.oatCream.withValues(alpha: 0.7),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
