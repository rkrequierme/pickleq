import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleq/views/login_view.dart';
import 'package:provider/provider.dart';
import 'package:pickleq/providers/app_state_provider.dart';

void main() {
  testWidgets('Login view compiles and renders basic elements', (WidgetTester tester) async {
    // Render LoginView with a dummy AppStateProvider (not initialized)
    await tester.pumpWidget(
      ChangeNotifierProvider<AppStateProvider>(
        create: (_) => AppStateProvider(),
        child: const MaterialApp(
          home: LoginView(),
        ),
      ),
    );

    // Verify presence of title, input fields and buttons
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
  });
}
