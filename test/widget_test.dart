import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amikom_student/core/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge displays correct text and renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            label: 'Aktif',
            variant: BadgeVariant.success,
          ),
        ),
      ),
    );

    expect(find.text('Aktif'), findsOneWidget);
  });
}
