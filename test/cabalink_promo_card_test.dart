import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cargolink/core/widgets/CabaLinkPromoCard.dart';

void main() {
  testWidgets('CabaLinkPromoCard renders in a SliverToBoxAdapter without crash',
      (tester) async {
    tester.view.physicalSize = const Size(454, 625);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: CabaLinkPromoCard()),
      ]),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('CabaLinkPromoCard fits narrow devices without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(381, 625);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: CabaLinkPromoCard()),
      ]),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}