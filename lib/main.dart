import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'services/local_storage_service.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/navigation_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await LocalStorageService.create();
  final state = AppState(storage: storage);
  runApp(AltitudeApp(state: state));
}

class AltitudeApp extends StatefulWidget {
  const AltitudeApp({super.key, required this.state});

  final AppState state;

  @override
  State<AltitudeApp> createState() => _AltitudeAppState();
}

class _AltitudeAppState extends State<AltitudeApp> {
  late final Future<void> _init = widget.state.init();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Altitude',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: FutureBuilder<void>(
          future: _init,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _SplashScreen();
            }
            if (snapshot.hasError) {
              return _ErrorScreen(error: snapshot.error.toString());
            }
            return const _RootSwitcher();
          },
        ),
      ),
    );
  }
}

class _RootSwitcher extends StatelessWidget {
  const _RootSwitcher();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      child: state.hasOnboarded
          ? const NavigationShell(key: ValueKey('shell'))
          : const WelcomeScreen(key: ValueKey('welcome')),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.espresso,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terrain_rounded, color: AppColors.caramel, size: 56),
            SizedBox(height: 12),
            Text(
              'ALTITUDE',
              style: TextStyle(
                color: AppColors.oatCream,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.caramel,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Something went wrong while loading',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
