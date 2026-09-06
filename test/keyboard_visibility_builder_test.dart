import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders its child when no builder is provided', (tester) async {
    const child = SizedBox(key: ValueKey('keyboard-child'));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: KeyboardVisibilityObserver(
          child: KeyboardVisibilityBuilder(child: child),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('keyboard-child')), findsOneWidget);
  });

  testWidgets('passes its child identity to the custom builder', (tester) async {
    const child = SizedBox(key: ValueKey('keyboard-child'));
    Widget? receivedChild;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KeyboardVisibilityObserver(
          child: KeyboardVisibilityBuilder(
            child: child,
            builder: (context, visibility, builderChild) {
              receivedChild = builderChild;
              return builderChild!;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(receivedChild, same(child));
  });

  testWidgets('retains the child state across keyboard metric changes', (tester) async {
    addTearDown(tester.view.resetViewInsets);
    _KeyboardChildState? initialState;
    const childKey = ValueKey('keyboard-child');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KeyboardVisibilityObserver(
          child: KeyboardVisibilityBuilder(
            child: _KeyboardChild(
              key: childKey,
              onStateCreated: (state) => initialState = state,
            ),
            builder: (context, visibility, child) => child!,
          ),
        ),
      ),
    );
    await tester.pump();

    final stateBeforeMetricChange = initialState;
    expect(stateBeforeMetricChange, isNotNull);
    expect(find.byKey(childKey), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 100);
    await tester.pump();

    expect(initialState, same(stateBeforeMetricChange));
    expect(find.byKey(childKey), findsOneWidget);
  });
}

class _KeyboardChild extends StatefulWidget {
  final ValueChanged<_KeyboardChildState> onStateCreated;

  const _KeyboardChild({super.key, required this.onStateCreated});

  @override
  State<_KeyboardChild> createState() => _KeyboardChildState();
}

class _KeyboardChildState extends State<_KeyboardChild> {
  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
