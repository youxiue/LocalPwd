import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/password_entries.dart';

part 'entry_dao.g.dart';

@DriftAccessor(tables: [PasswordEntries])
class EntryDao extends DatabaseAccessor<AppDatabase> with _$EntryDaoMixin {
  EntryDao(super.db);

  /// 条目列表流：按分类筛选，数据变更自动推送。
  /// 标题/账号关键字搜索在解密后于内存中完成（账号为密文，无法走 SQL）。
  Stream<List<PasswordEntry>> watchEntries({String? categoryId}) {
    final statement = select(passwordEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (categoryId != null) {
      statement.where((t) => t.categoryId.equals(categoryId));
    }
    return statement.watch();
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

  Future<int> deleteEntry(String id) {
    return (delete(passwordEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleFavorite(String id, bool favorite) {
    return (update(passwordEntries)..where((t) => t.id.equals(id)))
        .write(PasswordEntriesCompanion(isFavorite: Value(favorite)));
  }
}
