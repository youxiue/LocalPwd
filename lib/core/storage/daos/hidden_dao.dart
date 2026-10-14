import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/hidden_tables.dart';

part 'hidden_dao.g.dart';

@DriftAccessor(tables: [HiddenCategories, HiddenEntries])
class HiddenDao extends DatabaseAccessor<AppDatabase> with _$HiddenDaoMixin {
  HiddenDao(super.db);

  // ---- 隐藏条目 ----

  /// 隐藏条目列表流：可按分类筛选，数据变更自动推送。
  /// 标题已加密入库，不做 SQL 搜索，改在解密后内存过滤。
  Stream<List<HiddenPasswordEntry>> watchEntries({String? categoryId}) {
    final statement = select(hiddenEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (categoryId != null) {
      statement.where((t) => t.categoryId.equals(categoryId));
    }
    return statement.watch();
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

  Future<int> deleteEntry(String id) =>
      (delete(hiddenEntries)..where((t) => t.id.equals(id))).go();

  Future<void> toggleFavorite(String id, bool favorite) {
    return (update(hiddenEntries)..where((t) => t.id.equals(id)))
        .write(HiddenEntriesCompanion(isFavorite: Value(favorite)));
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

  Future<int> deleteCategory(String id) =>
      (delete(hiddenCategories)..where((t) => t.id.equals(id))).go();

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
