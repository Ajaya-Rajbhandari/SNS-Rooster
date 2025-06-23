import 'package:flutter/material.dart';

Color colorFromHex(String hex) {
  final h = hex.replaceAll('#', '');
  final v = int.parse(
    h.length == 6 ? 'FF$h' : h, // add alpha if missing
    radix: 16,
  );
  return Color(v);
}
