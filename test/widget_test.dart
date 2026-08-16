import 'package:flutter_test/flutter_test.dart';

import 'package:expenseflow/app/app.dart';

void main() {
  testWidgets('ExpenseFlow app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseFlowApp());

    expect(find.text('ExpenseFlow'), findsOneWidget);
    expect(find.text('Your finances, simplified.'), findsOneWidget);
  });
}
