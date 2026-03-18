import 'package:flutter/material.dart';
import 'google_auth_button_stub.dart'
    if (dart.library.html) 'google_auth_button_web.dart';

/// Renderiza o botão do Google adequado para a plataforma.
/// No Web, utiliza o botão oficial renderizado pelo GIS que evita bloqueadores de popups.
Widget buildGoogleAuthButton({required VoidCallback onPressed}) {
  return buildButton(onPressed: onPressed);
}
