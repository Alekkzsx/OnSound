// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onsound/main.dart';

/// Arquivo de testes de widget para o OnSoundApp.
/// Garante que os componentes visuais básicos sejam renderizados corretamente na inicialização.
void main() {
  /// Teste de fumaça (Smoke Test) para validar a inicialização do app.
  testWidgets('Teste de fumaça da OnSoundApp', (WidgetTester tester) async {
    // Constrói o aplicativo dentro do ambiente de teste.
    // O [ProviderScope] é necessário devido ao uso do Riverpod.
    await tester.pumpWidget(const ProviderScope(child: OnSoundApp()));

    // Verifica se os elementos textuais principais da Landing Screen estão presentes.
    // Procuramos pelo nome da marca 'ONSOUND' e pelo slogan.
    expect(find.text('ONSOUND'), findsOneWidget);
    expect(find.text('Sua música em qualquer lugar.'), findsOneWidget);
  });
}
