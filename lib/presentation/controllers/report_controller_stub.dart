// Mobile/Desktop stub — web_saver not used on non-web platforms
import 'dart:typed_data';

void saveFileWeb(Uint8List bytes, String fileName) {
  // No-op on non-web platforms; file is saved via path_provider instead
}
