import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  group('SeniorClarityMask', () {
    testWidgets('renders child inside ClarityMask', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeniorClarityMask(
            child: const Text('Sensitive'),
          ),
        ),
      );

      expect(find.text('Sensitive'), findsOneWidget);
      expect(find.byType(ClarityMask), findsOneWidget);
    });
  });

  group('SeniorClarityUnmask', () {
    testWidgets('renders child inside ClarityUnmask', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeniorClarityUnmask(
            child: const Text('Public'),
          ),
        ),
      );

      expect(find.text('Public'), findsOneWidget);
      expect(find.byType(ClarityUnmask), findsOneWidget);
    });
  });

  group('SeniorClarityMask + SeniorClarityUnmask combined', () {
    testWidgets('unmask works inside mask', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeniorClarityMask(
            child: Column(
              children: const [
                Text('Hidden'),
                SeniorClarityUnmask(
                  child: Text('Visible'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hidden'), findsOneWidget);
      expect(find.text('Visible'), findsOneWidget);
      expect(find.byType(ClarityMask), findsOneWidget);
      expect(find.byType(ClarityUnmask), findsOneWidget);
    });
  });
}
