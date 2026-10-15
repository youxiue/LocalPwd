import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/password_entries.dart';
import '../tables/entry_category_links.dart';

part 'entry_dao.g.dart';

@DriftAccessor(tables: [PasswordEntries, PasswordEntryCategories])
class EntryDao extends DatabaseAccessor<AppDatabase> with _$EntryDaoMixin {
  EntryDao(super.db);

  /// 条目列表流：按分类筛选（多对多关联），数据变更自动推送。
  /// 标题/账号关键字搜索在解密后于内存中完成（账号为密文，无法走 SQL）。
  Stream<List<PasswordEntry>> watchEntries({String? categoryId}) {
    if (categoryId == null) {
      return (select(passwordEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();
    }
    final query = select(passwordEntries).join([
      innerJoin(
        passwordEntryCategories,
        passwordEntryCategories.entryId.equalsExp(passwordEntries.id),
      ),
    ])
      ..where(passwordEntryCategories.categoryId.equals(categoryId))
      ..orderBy([OrderingTerm.desc(passwordEntries.updatedAt)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(passwordEntries)).toList());
  }

  /// 获取所有条目（按更新时间倒序）
  Future<List<PasswordEntry>> getAllEntries() {
    return (select(passwordEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<PasswordEntry?> getById(String id) {
    return (select(passwordEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> addEntry(PasswordEntriesCompanion entry) {
    return into(passwordEntries).insert(entry);
  }

  Future<bool> updateEntry(PasswordEntriesCompanion entry) {
    return (update(passwordEntries)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  Future<int> deleteEntry(String id) async {
    // 先清理分类关联，再删除条目本体
    await (delete(passwordEntryCategories)
          ..where((t) => t.entryId.equals(id)))
        .go();
    return (delete(passwordEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleFavorite(String id, bool favorite) {
    return (update(passwordEntries)..where((t) => t.id.equals(id)))
        .write(PasswordEntriesCompanion(isFavorite: Value(favorite)));
  }

  // ---- 条目-分类关联 ----

  /// 读取条目所属的全部分类 ID
  Future<List<String>> categoryIdsForEntry(String entryId) async {
    final rows = await (select(passwordEntryCategories)
          ..where((t) => t.entryId.equals(entryId)))
        .get();
    return rows.map((r) => r.categoryId).toList();
  }

  /// 重建条目的分类关联
  Future<void> setEntryCategories(String entryId, List<String> categoryIds) {
    return batch((b) {
      b.deleteWhere(
          passwordEntryCategories, (t) => t.entryId.equals(entryId));
      if (categoryIds.isNotEmpty) {
        b.insertAll(
          passwordEntryCategories,
          categoryIds
              .map((c) => PasswordEntryCategoriesCompanion.insert(
                    entryId: entryId,
                    categoryId: c,
                  ))
              .toList(),
        );
      }
    });
  }

  /// 全部关联关系（导出用）：entryId -> categoryId 列表
  Future<Map<String, List<String>>> allEntryCategoryLinks() async {
    final rows = await select(passwordEntryCategories).get();
    final map = <String, List<String>>{};
    for (final r in rows) {
      (map[r.entryId] ??= []).add(r.categoryId);
    }
    return map;
  }
}
