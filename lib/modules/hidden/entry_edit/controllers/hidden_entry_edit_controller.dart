import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:get/get.dart' hide Value;

import '../../../../core/services/auth_service.dart';
import '../../../../core/storage/database.dart';
import '../../../entry_edit/controllers/entry_edit_controller.dart';

/// 隐藏模式条目编辑控制器 — 复用普通模式的共享基类
class HiddenEntryEditController extends EntryEditControllerBase {
  final _db = Get.find<AppDatabase>();

  @override
  SecretKey? get sessionKey => AuthService.instance.hiddenSessionKey;

  @override
  Future<List<EntryCategoryOption>> loadCategories() async {
    final list = await _db.hiddenDao.getAllCategories();
    return list
        .map((c) => EntryCategoryOption(id: c.id, name: c.name))
        .toList();
  }

  @override
  Future<({String? title, List<String> categoryIds, String encryptedData})?>
      loadRawEntry(String id) async {
    final entry = await _db.hiddenDao.getById(id);
    if (entry == null) return null;
    return (
      title: null, // 标题已加密在 encryptedData 内，解密后由基类回填
      categoryIds: await _db.hiddenDao.categoryIdsForEntry(id),
      encryptedData: entry.encryptedData,
    );
  }

  @override
  Future<void> persistEntry({
    required String id,
    required bool isNew,
    required String title,
    required List<String> categoryIds,
    required String encryptedData,
  }) async {
    await _db.transaction(() async {
      if (isNew) {
        await _db.hiddenDao.addEntry(
          HiddenEntriesCompanion.insert(
            id: id,
            encryptedData: encryptedData,
          ),
        );
      } else {
        await _db.hiddenDao.updateEntry(
          HiddenEntriesCompanion(
            id: Value(id),
            encryptedData: Value(encryptedData),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      await _db.hiddenDao.setEntryCategories(id, categoryIds);
    });
  }
}
