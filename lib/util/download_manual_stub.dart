// Stub for non-web platforms.
import 'dart:typed_data';

Future<void> saveFileWeb(
  Uint8List bytes,
  String filename, {
  String mimeType =
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
}) async {
  throw UnsupportedError('saveFileWeb is only supported on web');
}
