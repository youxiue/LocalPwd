import 'package:drift/drift.dart';

/// 密码条目-分类关联表（多对多，支持一个条目属于多个分类）
@DataClassName('PasswordEntryCategoryLink')
class PasswordEntryCategories extends Table {
  TextColumn get entryId => text()();
  TextColumn get categoryId => text()();

  @override
  Set<Column> get primaryKey => {entryId, categoryId};
}

/// 隐藏模式条目-分类关联表（多对多，与普通模式隔离）
@DataClassName('HiddenEntryCategoryLink')
class HiddenEntryCategories extends Table {
  TextColumn get entryId => text()();
  TextColumn get categoryId => text()();

  @override
  Set<Column> get primaryKey => {entryId, categoryId};
}
