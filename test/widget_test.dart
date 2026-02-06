import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitoroute/core/widgets/user_avatar.dart';

void main() {
  testWidgets('UserAvatar displays correctly with image URL', (WidgetTester tester) async {
    // Test UserAvatar with image URL
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            imageUrl: 'https://example.com/avatar.jpg',
            name: 'John Doe',
            size: 50,
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
  });

  testWidgets('UserAvatar displays initials when no image provided', (WidgetTester tester) async {
    // Test UserAvatar without image URL
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            name: 'Jane Smith',
            size: 50,
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.text('JS'), findsOneWidget);
  });

  testWidgets('UserAvatar displays single initial when single name provided', (WidgetTester tester) async {
    // Test UserAvatar with single name
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            name: 'John',
            size: 50,
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
  });
}
