import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Makes [AppState] available down the tree and rebuilds dependents when it
/// notifies.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
