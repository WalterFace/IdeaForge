import 'package:altitude_app/main.dart';
import 'package:altitude_app/services/local_storage_service.dart';
import 'package:altitude_app/services/mock_pos_gateway.dart';
import 'package:altitude_app/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> pumpApp(WidgetTester tester, {bool onboarded = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(
    storage: LocalStorageService(prefs),
    posGateway: MockPosGateway(latency: Duration.zero),
  );
  if (onboarded) {
    await state.init();
    state.completeOnboarding(nickname: 'Judge');
  }
  await tester.binding.setSurfaceSize(const Size(375, 812));
  await tester.pumpWidget(AltitudeApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('shows welcome screen on first launch and continues to home',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Your campus, in a cup'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('ALTITUDE'), findsWidgets);
    expect(find.text('Rush Mode'), findsOneWidget);
    expect(find.text('Popular Now'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('Campus'), findsOneWidget);
  });

  testWidgets('home renders Gold loyalty card and tabs switch', (tester) async {
    final state = await pumpApp(tester, onboarded: true);
    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('1,240'), findsOneWidget);
    expect(find.textContaining('Judge'), findsWidgets);

    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 4);
    expect(find.text('Clubs & Events'), findsOneWidget);

    await tester.tap(find.text('Rewards'));
    await tester.pumpAndSettle();
    expect(find.text('How points work'), findsOneWidget);
  });

  testWidgets('cart badge updates when adding from menu', (tester) async {
    final state = await pumpApp(tester, onboarded: true);
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cookie');
    await tester.pumpAndSettle();
    expect(find.text('Chocolate Chip Cookie'), findsOneWidget);

    // Cookie has no customizations: quick add goes straight to the cart.
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    expect(state.cartCount, 1);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('rush mode opens and lists recommendations', (tester) async {
    await pumpApp(tester, onboarded: true);
    await tester.tap(find.text('I\'m in a rush'));
    await tester.pumpAndSettle();
    expect(find.text('Running late for class?\nWe\'ve got you.'), findsOneWidget);
    expect(find.text('Likely fits'), findsWidgets);
    expect(find.textContaining('Demo estimates only'), findsOneWidget);
  });
}
