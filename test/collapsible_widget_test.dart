import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('collapsible widget completes immediately for zero duration', (tester) async {
    final expanded = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: expanded,
            builder: (context, isExpanded, _) {
              return CollapsibleWidget(
                expanded: isExpanded,
                duration: Duration.zero,
                child: const SizedBox(width: 40, height: 20),
              );
            },
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(CollapsibleWidget)), Size.zero);

    expanded.value = true;
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(CollapsibleWidget)), const Size(40, 20));

    expanded.value = false;
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(CollapsibleWidget)), Size.zero);
  });
}
