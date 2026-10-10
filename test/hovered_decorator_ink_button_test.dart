import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HoveredDecorator keeps hover and tap active on its scaled edge', (tester) async {
    var taps = 0;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: HoveredDecorator(
            duration: Duration.zero,
            scale: 1.5,
            child: InkButton(
              onTap: () => taps++,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    await mouse.addPointer(location: const Offset(400, 300));
    await tester.pump();
    await mouse.moveTo(const Offset(400, 300));
    await tester.pump();

    // This point is outside the unscaled 100x100 box, but inside its 1.5x
    // visual bounds. It must not make the pointer leave the decorator.
    const scaledEdge = Offset(460, 300);
    await mouse.moveTo(scaledEdge);
    await tester.pump();

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1.5);

    await mouse.down(scaledEdge);
    await mouse.up();
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('HoveredDecorator opts into a clipped shape for a direct InkWell', (tester) async {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    await tester.pumpWidget(
      MaterialApp(
        home: HoveredDecorator(
          shape: shape,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(shape: shape, color: Colors.blue),
          child: InkWell(
            customBorder: shape,
            onTap: () {},
            child: const SizedBox(width: 100, height: 48),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(find.byType(Material));
    expect(material.shape, same(shape));
    expect(material.clipBehavior, Clip.antiAlias);
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.customBorder, same(shape));
  });

  testWidgets('InkButton forwards InkWell interaction and appearance properties', (tester) async {
    var taps = 0;
    var doubleTaps = 0;
    var longPresses = 0;
    var longPressUps = 0;
    var tapDowns = 0;
    var tapUps = 0;
    var tapCancels = 0;
    var secondaryTaps = 0;
    var secondaryTapDowns = 0;
    var secondaryTapUps = 0;
    var secondaryTapCancels = 0;
    final highlightChanges = <bool>[];
    final hoverChanges = <bool>[];
    final focusChanges = <bool>[];
    final focusNode = FocusNode();
    final statesController = WidgetStatesController();
    addTearDown(focusNode.dispose);
    addTearDown(statesController.dispose);

    final overlayColor = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.hovered) ? Colors.orange : Colors.purple,
    );
    final customBorder = const StadiumBorder();

    await tester.pumpWidget(
      MaterialApp(
        home: InkButton(
          onTap: () => taps++,
          onDoubleTap: () => doubleTaps++,
          onLongPress: () => longPresses++,
          onLongPressUp: () => longPressUps++,
          onTapDown: (_) => tapDowns++,
          onTapUp: (_) => tapUps++,
          onTapCancel: () => tapCancels++,
          onSecondaryTap: () => secondaryTaps++,
          onSecondaryTapDown: (_) => secondaryTapDowns++,
          onSecondaryTapUp: (_) => secondaryTapUps++,
          onSecondaryTapCancel: () => secondaryTapCancels++,
          onHighlightChanged: highlightChanges.add,
          onHover: hoverChanges.add,
          mouseCursor: SystemMouseCursors.forbidden,
          focusColor: Colors.red,
          hoverColor: Colors.green,
          highlightColor: Colors.blue,
          overlayColor: overlayColor,
          splashColor: Colors.yellow,
          splashFactory: InkRipple.splashFactory,
          radius: 23,
          customBorder: customBorder,
          enableFeedback: false,
          excludeFromSemantics: true,
          focusNode: focusNode,
          canRequestFocus: false,
          onFocusChange: focusChanges.add,
          autofocus: false,
          statesController: statesController,
          hoverDuration: const Duration(milliseconds: 90),
          child: const SizedBox(width: 100, height: 48),
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNotNull);
    expect(inkWell.onDoubleTap, isNotNull);
    expect(inkWell.onLongPress, isNotNull);
    expect(inkWell.onLongPressUp, isNotNull);
    expect(inkWell.onTapDown, isNotNull);
    expect(inkWell.onTapUp, isNotNull);
    expect(inkWell.onTapCancel, isNotNull);
    expect(inkWell.onSecondaryTap, isNotNull);
    expect(inkWell.onSecondaryTapDown, isNotNull);
    expect(inkWell.onSecondaryTapUp, isNotNull);
    expect(inkWell.onSecondaryTapCancel, isNotNull);
    expect(inkWell.mouseCursor, SystemMouseCursors.forbidden);
    expect(inkWell.focusColor, Colors.red);
    expect(inkWell.hoverColor, Colors.green);
    expect(inkWell.highlightColor, Colors.blue);
    expect(inkWell.overlayColor, same(overlayColor));
    expect(inkWell.splashColor, Colors.yellow);
    expect(inkWell.splashFactory, InkRipple.splashFactory);
    expect(inkWell.radius, 23);
    expect(inkWell.customBorder, same(customBorder));
    expect(inkWell.enableFeedback, isFalse);
    expect(inkWell.excludeFromSemantics, isTrue);
    expect(inkWell.focusNode, same(focusNode));
    expect(inkWell.canRequestFocus, isFalse);
    expect(inkWell.onFocusChange, isNotNull);
    expect(inkWell.autofocus, isFalse);
    expect(inkWell.statesController, same(statesController));
    expect(inkWell.hoverDuration, const Duration(milliseconds: 90));

    await tester.tap(find.byType(InkButton));
    await tester.pump(kDoubleTapTimeout);
    await tester.pump();
    expect(taps, 1);
    expect(tapDowns, 1);
    expect(tapUps, 1);
    expect(highlightChanges, containsAllInOrder(<bool>[true, false]));
    expect(doubleTaps, 0);
    expect(longPresses, 0);
    expect(longPressUps, 0);
    expect(tapCancels, 0);
    expect(secondaryTaps, 0);
    expect(secondaryTapDowns, 0);
    expect(secondaryTapUps, 0);
    expect(secondaryTapCancels, 0);
    expect(hoverChanges, isEmpty);
    expect(focusChanges, isEmpty);
  });

  testWidgets('InkButton uses its custom border for both Material and InkWell', (tester) async {
    const customBorder = StadiumBorder();

    await tester.pumpWidget(
      const MaterialApp(
        home: InkButton(
          customBorder: customBorder,
          child: SizedBox(width: 100, height: 48),
        ),
      ),
    );

    final material = tester.widget<Material>(find.byType(Material));
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(material.shape, customBorder);
    expect(material.clipBehavior, Clip.hardEdge);
    expect(inkWell.customBorder, customBorder);
  });

  testWidgets('InkButton retains its existing outline when a custom ink border is added', (tester) async {
    const outline = BorderSide(color: Colors.red, width: 2);
    const customBorder = StadiumBorder();

    await tester.pumpWidget(
      const MaterialApp(
        home: InkButton(
          border: outline,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          customBorder: customBorder,
          child: SizedBox(width: 100, height: 48),
        ),
      ),
    );

    final material = tester.widget<Material>(find.byType(Material));
    final materialShape = material.shape! as RoundedRectangleBorder;
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(materialShape.side, outline);
    expect(materialShape.borderRadius, const BorderRadius.all(Radius.circular(12)));
    expect(inkWell.customBorder, customBorder);
  });

  testWidgets('InkButton paints its decoration below the ink and takes the shape from it', (tester) async {
    const decoration = BoxDecoration(
      gradient: LinearGradient(colors: [Colors.red, Colors.blue]),
      borderRadius: BorderRadius.all(Radius.circular(12)),
      boxShadow: [BoxShadow(blurRadius: 4)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: InkButton(
            onTap: () {},
            decoration: decoration,
            child: const SizedBox(width: 100, height: 48),
          ),
        ),
      ),
    );

    final button = find.byType(InkButton);
    final decorated = tester.widget<DecoratedBox>(find.descendant(of: button, matching: find.byType(DecoratedBox)).first);
    expect(decorated.decoration, same(decoration));
    // The decoration sits outside the Material, so the ink is painted above it.
    expect(find.descendant(of: find.byWidget(decorated), matching: find.byType(Material)), findsOneWidget);

    const expectedShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
    final material = tester.widget<Material>(find.descendant(of: button, matching: find.byType(Material)));
    expect(material.shape, expectedShape);
    expect(material.color, Colors.transparent);
    expect(tester.widget<InkWell>(find.byType(InkWell)).customBorder, expectedShape);
  });

  testWidgets('InkButton derives a circle and a ShapeDecoration shape', (tester) async {
    const stadium = StadiumBorder();

    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            InkButton(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red),
              child: SizedBox(width: 48, height: 48),
            ),
            InkButton(
              decoration: ShapeDecoration(shape: stadium, color: Colors.red),
              child: SizedBox(width: 100, height: 48),
            ),
          ],
        ),
      ),
    );

    final inkWells = tester.widgetList<InkWell>(find.byType(InkWell)).toList();
    expect(inkWells[0].customBorder, const CircleBorder());
    expect(inkWells[1].customBorder, stadium);
  });

  testWidgets('InkButton forwards clipBehavior to its Material', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InkButton(
          clipBehavior: Clip.none,
          child: SizedBox(width: 100, height: 48),
        ),
      ),
    );

    expect(tester.widget<Material>(find.descendant(of: find.byType(InkButton), matching: find.byType(Material))).clipBehavior, Clip.none);
  });

  testWidgets('InkButton with foregroundInk draws the ink above the child and keeps tapping', (tester) async {
    var taps = 0;
    const childKey = Key('child');

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: InkButton(
            onTap: () => taps++,
            foregroundInk: true,
            padding: const EdgeInsets.all(8),
            child: const ColoredBox(
              color: Colors.red,
              child: SizedBox(key: childKey, width: 100, height: 48),
            ),
          ),
        ),
      ),
    );

    final inkWell = find.byType(InkWell);
    expect(tester.widget<InkWell>(inkWell).child, isNull);
    // The InkWell hosts its ink on a Material that is above the child, not on the outer one.
    final inkMaterial = tester.widget<Material>(find.ancestor(of: inkWell, matching: find.byType(Material)).first);
    expect(inkMaterial.type, MaterialType.transparency);
    expect(find.descendant(of: find.byWidget(inkMaterial), matching: find.byKey(childKey)), findsNothing);
    expect(tester.getSize(inkWell), tester.getSize(find.byType(InkButton)));
    expect(tester.getSize(find.byType(InkButton)), const Size(116, 64));

    await tester.tap(find.byType(InkButton));
    await tester.pump(kDoubleTapTimeout);
    expect(taps, 1);
  });

  testWidgets('HoveredDecorator composes with transparent and opaque InkButton materials', (tester) async {
    const transparentKey = Key('transparent');
    const opaqueKey = Key('opaque');

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            HoveredDecorator(
              key: transparentKey,
              decoration: const BoxDecoration(color: Colors.black),
              child: InkButton(
                onTap: () {},
                backgroundColor: Colors.transparent,
                child: const SizedBox(width: 100, height: 48),
              ),
            ),
            HoveredDecorator(
              key: opaqueKey,
              decoration: const BoxDecoration(color: Colors.black),
              child: InkButton(
                onTap: () {},
                backgroundColor: Colors.red,
                child: const SizedBox(width: 100, height: 48),
              ),
            ),
          ],
        ),
      ),
    );

    final transparentMaterials = tester.widgetList<Material>(
      find.descendant(of: find.byKey(transparentKey), matching: find.byType(Material)),
    );
    final opaqueMaterials = tester.widgetList<Material>(
      find.descendant(of: find.byKey(opaqueKey), matching: find.byType(Material)),
    );
    expect(transparentMaterials, hasLength(2));
    expect(opaqueMaterials, hasLength(2));
    expect(transparentMaterials.last.color, Colors.transparent);
    expect(opaqueMaterials.last.color, Colors.red);
  });

  testWidgets('HoveredDecorator around InkButton retains a single button semantics node', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HoveredDecorator(
          decoration: const BoxDecoration(color: Colors.black),
          hoveredDecoration: const BoxDecoration(color: Colors.white),
          child: InkButton(
            onTap: () {},
            backgroundColor: Colors.transparent,
            child: Semantics(
              label: 'Save',
              button: true,
              child: const SizedBox(width: 100, height: 48),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Save')),
      matchesSemantics(
        label: 'Save',
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });
}
