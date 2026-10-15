import 'package:drift/drift.dart';

/// 密码条目表
/// title 为明文（列表展示用），其余敏感字段统一加密为 encryptedData
/// 条目与分类为多对多关系，关联存储在 PasswordEntryCategories 表
@DataClassName('PasswordEntry')
class PasswordEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  /// 加密 JSON: {username, password, url, notes, customFields}
  TextColumn get encryptedData => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
