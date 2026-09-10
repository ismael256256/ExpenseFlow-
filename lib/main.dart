import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/transactions/application/transaction_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TransactionStore.instance.initialize();
  runApp(const ExpenseFlowApp());
}
