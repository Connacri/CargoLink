import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cargolink/screens/shared/Guide_cabaLink.dart';

void main() {
  testWidgets('CabaLinkPage renders and scrolls without crashing',
      (tester) async {
    tester.view.physicalSize = const Size(454, 625);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CabaLinkPage()));
    await tester.pump(const Duration(milliseconds: 1200));

    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    for (int i = 0; i < 15; i++) {
      await tester.fling(scrollable, const Offset(0, -900), 4000);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    }

    await tester.fling(scrollable, const Offset(0, 900), 4000);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.fling(scrollable, const Offset(0, 900), 1000);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
  });

  testWidgets('CabaLinkPage supports Arabic RTL and chapter expansion',
      (tester) async {
    tester.view.physicalSize = const Size(454, 625);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CabaLinkPage()));
    await tester.pump(const Duration(milliseconds: 1200));

    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    await tester.fling(scrollable, const Offset(0, -4000), 6000);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);

    final chapter = find.text('1.');
    if (chapter.evaluate().isNotEmpty) {
      await tester.tap(chapter.first);
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.takeException(), isNull);

    final toggle = find.text('AR');
    expect(toggle, findsWidgets);

    for (int i = 0; i < 30; i++) {
      await tester.fling(scrollable, const Offset(0, 1500), 4000);
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(toggle.first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    final dir = tester
        .widget<Directionality>(find.ancestor(
          of: scrollable,
          matching: find.byType(Directionality),
        ).first)
        .textDirection;
    expect(dir, TextDirection.rtl);

    await tester.fling(scrollable, const Offset(0, -900), 4000);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
  });

  testWidgets('CabaLinkPage fits narrow devices without overflow', (tester) async {
    tester.view.physicalSize = const Size(381, 625);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CabaLinkPage()));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);

    final scrollable = find.byType(CustomScrollView);
    for (int i = 0; i < 15; i++) {
      await tester.fling(scrollable, const Offset(0, -900), 4000);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
  });
}