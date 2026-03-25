import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onsound/main.dart';

void main() {
  testWidgets('Landing renderiza marca OnSound', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OnSoundApp()));

    expect(find.text('ONSOUND'), findsOneWidget);
    expect(find.textContaining('biblioteca de musica'), findsOneWidget);
  });
}
