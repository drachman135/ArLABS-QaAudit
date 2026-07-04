import 'dart:typed_data';

Future<void> downloadFile({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  throw UnsupportedError('downloadFile is only supported on web');
}
