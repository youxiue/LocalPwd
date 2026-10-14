import 'package:drift/drift.dart';

/// 隐藏模式分类表 — 独立于正常分类
@DataClassName('HiddenCategoryEntry')
class HiddenCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#424242'))();
  TextColumn get icon => text().withDefault(const Constant('visibility_off'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 隐藏模式密码条目表 — 与正常条目完全隔离
/// 标题与正文统一加密在 encryptedData 内，表中不保留可辨识的明文字段
@DataClassName('HiddenPasswordEntry')
class HiddenEntries extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get encryptedData => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
