import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigcredit/app/app.dart';

void main() {
  testWidgets('App mounts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GigCreditApp()),
    );
    // pump a single frame to let GoRouter initialise redirect
    await tester.pump();
    // Drain any pending timers (splash screen 1.5s timer etc.)
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
