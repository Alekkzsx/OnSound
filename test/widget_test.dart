import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onsound/core/services/auth_service.dart';
import 'package:onsound/main.dart';

void main() {
  testWidgets('Landing renderiza marca OnSound', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLoadingProvider.overrideWith((ref) => false),
          authStateProvider.overrideWith((ref) => null),
        ],
        child: const OnSoundApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ONSOUND'), findsOneWidget);
    expect(find.textContaining('biblioteca de musica'), findsOneWidget);
  });
}
