import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class EventImage extends StatelessWidget {
  const EventImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final source = imageUrl?.trim();
    if (source == null || source.isEmpty) return fallback;

    if (source.startsWith('data:image')) {
      final separator = source.indexOf(',');
      if (separator < 0) return fallback;

      try {
        final bytes = base64Decode(source.substring(separator + 1));
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      } on FormatException {
        return fallback;
      }
    }

    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return fallback;
  }
}
