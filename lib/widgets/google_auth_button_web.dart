import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildButton({required VoidCallback onPressed}) {
  return SizedBox(
    height: 50,
    child: web.renderButton(),
  );
}
