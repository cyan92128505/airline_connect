import 'dart:io';
import 'package:app/objectbox.g.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';

class TestObjectBoxFactory {
  static Future<ObjectBox> create() async {
    final tempDir = await Directory.systemTemp.createTemp('objectbox_test_');
    final store = await openStore(directory: tempDir.path);

    return ObjectBox.createFromStore(store);
  }

  static Future<void> cleanup(ObjectBox objectBox, Directory tempDir) async {
    objectBox.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}
