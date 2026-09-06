import 'dart:async';

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

  testWidgets('resumes expansion after the same keyed widget is reparented', (tester) async {
    await _expectAnimationCompletesAfterReparent(tester, initiallyExpanded: false);
  });

  testWidgets('resumes collapse after the same keyed widget is reparented', (tester) async {
    await _expectAnimationCompletesAfterReparent(tester, initiallyExpanded: true);
  });
}

Future<void> _expectAnimationCompletesAfterReparent(
  WidgetTester tester, {
  required bool initiallyExpanded,
}) async {
  final collapsibleKey = GlobalKey();
  final harnessKey = GlobalKey<_ReparentingHarnessState>();
  final timers = _PeriodicTimerTracker();

  await timers.track(() async {
    await tester.pumpWidget(
      _ReparentingHarness(
        key: harnessKey,
        collapsibleKey: collapsibleKey,
        initiallyExpanded: initiallyExpanded,
      ),
    );
    if (initiallyExpanded) {
      await _waitAndPump(tester, const Duration(milliseconds: 330));
    }

    harnessKey.currentState!.toggleExpanded();
    await tester.pump();
    await _waitAndPump(tester, const Duration(milliseconds: 90));

    final sizeDuringAnimation = tester.getSize(find.byKey(collapsibleKey));
    expect(sizeDuringAnimation.height, inExclusiveRange(0.0, 20.0));

    harnessKey.currentState!.reparent();
    await tester.pump();

    expect(tester.getSize(find.byKey(collapsibleKey)), sizeDuringAnimation);
    expect(timers.activePeriodicTimers, 1);

    await _waitAndPump(tester, const Duration(milliseconds: 250));

    expect(
      tester.getSize(find.byKey(collapsibleKey)),
      initiallyExpanded ? Size.zero : const Size(40, 20),
    );
    expect(timers.activePeriodicTimers, 0);
    expect(timers.maximumActivePeriodicTimers, 1);
  });
}

Future<void> _waitAndPump(WidgetTester tester, Duration duration) async {
  await tester.runAsync(() => Future<void>.delayed(duration));
  await tester.pump(duration);
}

class _ReparentingHarness extends StatefulWidget {
  const _ReparentingHarness({
    super.key,
    required this.collapsibleKey,
    required this.initiallyExpanded,
  });

  final GlobalKey collapsibleKey;
  final bool initiallyExpanded;

  @override
  State<_ReparentingHarness> createState() => _ReparentingHarnessState();
}

class _ReparentingHarnessState extends State<_ReparentingHarness> {
  late bool _expanded = widget.initiallyExpanded;
  var _useFirstParent = true;

  void toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void reparent() {
    setState(() {
      _useFirstParent = !_useFirstParent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final collapsible = CollapsibleWidget(
      key: widget.collapsibleKey,
      expanded: _expanded,
      duration: const Duration(milliseconds: 300),
      child: const SizedBox(width: 40, height: 20),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Align(child: _useFirstParent ? collapsible : null),
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: Align(child: _useFirstParent ? null : collapsible),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodicTimerTracker {
  var activePeriodicTimers = 0;
  var maximumActivePeriodicTimers = 0;

  Future<void> track(Future<void> Function() body) {
    return runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        createPeriodicTimer: (self, parent, zone, duration, callback) {
          late _TrackedPeriodicTimer trackedTimer;
          final timer = parent.createPeriodicTimer(
            zone,
            duration,
            (_) => callback(trackedTimer),
          );
          trackedTimer = _TrackedPeriodicTimer(timer, _timerCancelled);
          activePeriodicTimers++;
          maximumActivePeriodicTimers = activePeriodicTimers > maximumActivePeriodicTimers ? activePeriodicTimers : maximumActivePeriodicTimers;
          return trackedTimer;
        },
      ),
    );
  }

  void _timerCancelled() {
    activePeriodicTimers--;
  }
}

class _TrackedPeriodicTimer implements Timer {
  _TrackedPeriodicTimer(this._timer, this._onCancel);

  final Timer _timer;
  final VoidCallback _onCancel;
  var _cancelled = false;

  @override
  bool get isActive => _timer.isActive;

  @override
  int get tick => _timer.tick;

  @override
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _onCancel();
    }
    _timer.cancel();
  }
}
