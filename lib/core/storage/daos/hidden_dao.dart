import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/hidden_tables.dart';
import '../tables/entry_category_links.dart';

part 'hidden_dao.g.dart';

@DriftAccessor(tables: [HiddenCategories, HiddenEntries, HiddenEntryCategories])
class HiddenDao extends DatabaseAccessor<AppDatabase> with _$HiddenDaoMixin {
  HiddenDao(super.db);

  // ---- 隐藏条目 ----

  /// 隐藏条目列表流：可按分类筛选（多对多关联），数据变更自动推送。
  /// 标题已加密入库，不做 SQL 搜索，改在解密后内存过滤。
  Stream<List<HiddenPasswordEntry>> watchEntries({String? categoryId}) {
    if (categoryId == null) {
      return (select(hiddenEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();
    }
    final query = select(hiddenEntries).join([
      innerJoin(
        hiddenEntryCategories,
        hiddenEntryCategories.entryId.equalsExp(hiddenEntries.id),
      ),
    ])
      ..where(hiddenEntryCategories.categoryId.equals(categoryId))
      ..orderBy([OrderingTerm.desc(hiddenEntries.updatedAt)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(hiddenEntries)).toList());
  }

  Future<List<HiddenPasswordEntry>> getAllEntries() {
    return (select(hiddenEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<HiddenPasswordEntry?> getById(String id) {
    return (select(hiddenEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> addEntry(HiddenEntriesCompanion entry) =>
      into(hiddenEntries).insert(entry);

  Future<bool> updateEntry(HiddenEntriesCompanion entry) =>
      (update(hiddenEntries)..where((t) => t.id.equals(entry.id.value)))
          .write(entry)
          .then((r) => r > 0);

  Future<int> deleteEntry(String id) async {
    // 先清理分类关联，再删除条目本体
    await (delete(hiddenEntryCategories)..where((t) => t.entryId.equals(id)))
        .go();
    return (delete(hiddenEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleFavorite(String id, bool favorite) {
    return (update(hiddenEntries)..where((t) => t.id.equals(id)))
        .write(HiddenEntriesCompanion(isFavorite: Value(favorite)));
  }

  // ---- 条目-分类关联 ----

  /// 读取条目所属的全部分类 ID
  Future<List<String>> categoryIdsForEntry(String entryId) async {
    final rows = await (select(hiddenEntryCategories)
          ..where((t) => t.entryId.equals(entryId)))
        .get();
    return rows.map((r) => r.categoryId).toList();
  }

  /// 重建条目的分类关联
  Future<void> setEntryCategories(String entryId, List<String> categoryIds) {
    return batch((b) {
      b.deleteWhere(hiddenEntryCategories, (t) => t.entryId.equals(entryId));
      if (categoryIds.isNotEmpty) {
        b.insertAll(
          hiddenEntryCategories,
          categoryIds
              .map((c) => HiddenEntryCategoriesCompanion.insert(
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
    final rows = await select(hiddenEntryCategories).get();
    final map = <String, List<String>>{};
    for (final r in rows) {
      (map[r.entryId] ??= []).add(r.categoryId);
    }
    return map;
  }

  // ---- 隐藏分类 ----

  Future<List<HiddenCategoryEntry>> getAllCategories() {
    return (select(hiddenCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Stream<List<HiddenCategoryEntry>> watchAllCategories() {
    return (select(hiddenCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<int> addCategory(HiddenCategoriesCompanion c) =>
      into(hiddenCategories).insert(c);

  Future<bool> updateCategory(HiddenCategoriesCompanion c) =>
      (update(hiddenCategories)..where((t) => t.id.equals(c.id.value)))
          .write(c)
          .then((r) => r > 0);

  Future<int> deleteCategory(String id) async {
    // 删除分类时同步清理条目关联
    await (delete(hiddenEntryCategories)
          ..where((t) => t.categoryId.equals(id)))
        .go();
    return (delete(hiddenCategories)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateSortOrder(List<String> ids) async {
    await batch((b) {
      for (var i = 0; i < ids.length; i++) {
        b.update(
          hiddenCategories,
          HiddenCategoriesCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(ids[i]),
        );
      }
    });
  }
}
