import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novels_destiny/core/widgets/app_text_field.dart';

void main() {
  group('AppTextField GetX ValueBuilder Tests', () {
    testWidgets('Password field shows visibility_off icon initially and toggles on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              isPassword: true,
              hint: 'Enter password',
            ),
          ),
        ),
      );

      // Initially password is obscured, visibility_off icon is displayed
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      TextField textField = tester.widget(find.byType(TextField));
      expect(textField.obscureText, true);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Now visibility icon is displayed and text is revealed
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      textField = tester.widget(find.byType(TextField));
      expect(textField.obscureText, false);

      // Tap toggle again to obscure
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      textField = tester.widget(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('Non-password field does not show password toggle icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              isPassword: false,
              label: 'Username',
              hint: 'Enter username',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, false);
    });

    testWidgets('Non-password field respects obscureText parameter from parent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              isPassword: false,
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });
  });
}
