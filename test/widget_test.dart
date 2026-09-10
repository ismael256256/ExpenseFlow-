import 'package:flutter_test/flutter_test.dart';
import 'package:expenseflow/app/app.dart';
import 'package:expenseflow/features/transactions/application/transaction_store.dart';

void main() {
  testWidgets('ExpenseFlow dashboard loads', (WidgetTester tester) async {
    await TransactionStore.instance.initialize();

    await tester.pumpWidget(const ExpenseFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('ExpenseFlow'), findsOneWidget);
    expect(find.text('Your finances at a glance'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
  });
}
