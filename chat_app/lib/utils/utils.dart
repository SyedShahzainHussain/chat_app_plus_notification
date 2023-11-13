import 'dart:io';

import 'package:image_picker/image_picker.dart';

class Utils {
  static Future<dynamic> pickImage() async {
    final _picker = await ImagePicker().pickImage(
        source: ImageSource.camera, maxWidth: 1400, imageQuality: 50);
    if (_picker != null) {
      return File(_picker.path);
    }
    return null;
  }
}
