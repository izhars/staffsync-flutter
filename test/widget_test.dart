import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/main.dart';
import 'package:staffsync/main.dart';
import 'package:staffsync/utils/my_app_constants.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app with required parameters
    await tester.pumpWidget(
      MyApp(
        initialNotificationData: null,
        isFromNotification: false,
      ),
    );

    // Or if you have a simpler test app setup
    await tester.pumpWidget(
      MaterialApp(
        home: Container(),
      ),
    );
  });
}