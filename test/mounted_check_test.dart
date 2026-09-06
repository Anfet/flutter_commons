import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

class _MountedCheckWidget extends StatefulWidget {
  const _MountedCheckWidget();

  @override
  State<_MountedCheckWidget> createState() => _MountedCheckState();
}

class _MountedCheckState extends State<_MountedCheckWidget> with MountedCheck {
  Future<T> check<T>(FutureOr<T> value) => ifMounted<T>(value);

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('ifMounted rejects a pending future completed after unmount', (tester) async {
    final pending = Completer<String>();
    await tester.pumpWidget(const _MountedCheckWidget());
    final state = tester.state<_MountedCheckState>(find.byType(_MountedCheckWidget));

    final result = state.check(pending.future);
    await tester.pumpWidget(const SizedBox());
    pending.complete('done');

    await expectLater(result, throwsA(isA<FlowException>()));
  });

  testWidgets('ifMounted preserves typed synchronous and asynchronous values', (tester) async {
    await tester.pumpWidget(const _MountedCheckWidget());
    final state = tester.state<_MountedCheckState>(find.byType(_MountedCheckWidget));

    final synchronous = state.check<int>(42);
    final asynchronous = state.check<String>(Future<String>.value('done'));

    expect(await synchronous, 42);
    expect(await asynchronous, 'done');
  });

  testWidgets('ifMounted propagates source errors even after unmount', (tester) async {
    final pending = Completer<String>();
    await tester.pumpWidget(const _MountedCheckWidget());
    final state = tester.state<_MountedCheckState>(find.byType(_MountedCheckWidget));

    final result = state.check(pending.future);
    await tester.pumpWidget(const SizedBox());
    pending.completeError(StateError('source failed'));

    await expectLater(result, throwsA(isA<StateError>()));
  });
}
