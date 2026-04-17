import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperService {
  static const _fileName = 'custom_wallpaper.img';
  static final ImagePicker _picker = ImagePicker();

  /// Opens the system gallery picker, copies the chosen image into the app's
  /// documents directory, and returns the persisted path. Returns null if the
  /// user cancelled.
  static Future<String?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2160,
    );
    if (picked == null) return null;
    return _persist(File(picked.path));
  }

  static Future<String> _persist(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/$_fileName');
    if (await target.exists()) {
      await target.delete();
    }
    await source.copy(target.path);
    return target.path;
  }

  static Future<void> clear() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (await file.exists()) await file.delete();
  }
}
