import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opennutritracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Policy Test', () {
    testWidgets('Should require policy confirmation before proceeding',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Find the "Start" button
      final startButton = find.text('START');
      expect(startButton, findsOneWidget, reason: 'The Start button should be visible');

      // Try to tap the start button without accepting policy
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify we are still on the first page
      expect(find.text('Welcome to'), findsOneWidget, 
          reason: 'We should stay on the first page because the policy was not accepted');

      // Find and tap the policy checkbox
      final policyCheckbox = find.byType(Checkbox).first;
      expect(startButton, findsOneWidget, reason: 'The policy button should be visible');

      await tester.tap(policyCheckbox);
      await tester.pumpAndSettle();

      // Now try to tap the start button again
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify we've moved to the next page (gender selection)
      expect(find.text('Gender'), findsOneWidget,
        reason: 'We should advance to the gender selection page after accepting the policy');
    });
  });
} 