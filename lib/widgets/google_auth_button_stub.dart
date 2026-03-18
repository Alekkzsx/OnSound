import 'package:flutter/material.dart';

Widget buildButton({required VoidCallback onPressed}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.login),
    label: const Text(
      'Entrar com Google',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}
