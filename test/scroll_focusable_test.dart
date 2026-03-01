import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calls onFocused on false->true edge', (tester) async {
    final focusNotifier = ValueNotifier<bool>(false);
    var focusedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ValueListenableBuilder<bool>(
              valueListenable: focusNotifier,
              builder: (context, focus, _) {
                return Column(
                  children: [
                    const SizedBox(height: 600),
                    ScrollFocusable(
                      focus: focus,
                      duration: const Duration(milliseconds: 1),
                      onFocused: () => focusedCount++,
                      child: const SizedBox(height: 40, child: Text('Target')),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(focusedCount, 0);

    focusNotifier.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(focusedCount, 1);
  });

  testWidgets('does not re-trigger on true->true', (tester) async {
    final focusNotifier = ValueNotifier<bool>(true);
    var focusedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ValueListenableBuilder<bool>(
              valueListenable: focusNotifier,
              builder: (context, focus, _) {
                return Column(
                  children: [
                    const SizedBox(height: 600),
                    ScrollFocusable(
                      focus: focus,
                      duration: const Duration(milliseconds: 1),
                      onFocused: () => focusedCount++,
                      child: const SizedBox(height: 40, child: Text('Target')),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(focusedCount, 1);

    focusNotifier.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(focusedCount, 1);
  });
}
