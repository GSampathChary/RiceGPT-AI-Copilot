import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/app/app.dart';
import 'package:mobile/core/state/app_state.dart';

void main() {
  testWidgets('RiceGPT app boots into the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const RiceGptApp(),
      ),
    );

    expect(find.text('RiceGPT AI'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

