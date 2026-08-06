import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hara_app/config/colors.dart';
import 'package:hara_app/config/constants.dart';

void main() {
  testWidgets('App branding shows app name', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Text(AppConstants.appName,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
    ));
    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
