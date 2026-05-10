import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_shield/features/report/presentation/screens/home_screen.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}