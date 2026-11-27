import 'dart:convert';
import 'dart:typed_data';

import 'package:eventify_campus/services/event_service.dart';
import 'package:eventify_campus/widgets/event_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('encodes bounded JPEG bytes as a data URI', () {
    final bytes = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 1, height: 1)),
    );
    final dataUri = EventService.encodeEventImage(bytes);

    expect(dataUri, startsWith('data:image/jpeg;base64,'));
    expect(base64Decode(dataUri.split(',').last), bytes);
  });

  test(
    'compresses picked images into JPEG below the Firestore size limit',
    () async {
      final sourceImage = img.Image(width: 1600, height: 900);
      img.fill(sourceImage, color: img.ColorRgb8(32, 96, 180));
      final source = Uint8List.fromList(img.encodePng(sourceImage));
      final compressed = await compressEventImage(source);

      expect(compressed.length, lessThanOrEqualTo(maxEventImageBytes));
      expect(compressed[0], 0xff);
      expect(compressed[1], 0xd8);
      final decoded = img.decodeJpg(compressed);
      expect(decoded?.width, 800);
      expect(decoded?.height, 450);
    },
  );

  testWidgets('renders base64 image data from a data URI', (tester) async {
    final pngBytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 1, height: 1)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EventImage(
          imageUrl: 'data:image/png;base64,${base64Encode(pngBytes)}',
          fallback: const SizedBox(key: Key('fallback')),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const Key('fallback')), findsNothing);
  });
}
