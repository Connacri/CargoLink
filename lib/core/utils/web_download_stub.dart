import 'dart:typed_data';

/// No-op outside the web platform. The real implementation lives in
/// `web_download.dart` and is only compiled on web via a conditional import.
void downloadBytesOnWeb(Uint8List bytes, String fileName) {}
