// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hidden_dao.dart';

// ignore_for_file: type=lint
mixin _$HiddenDaoMixin on DatabaseAccessor<AppDatabase> {
  $HiddenCategoriesTable get hiddenCategories =>
      attachedDatabase.hiddenCategories;
  $HiddenEntriesTable get hiddenEntries => attachedDatabase.hiddenEntries;
  HiddenDaoManager get managers => HiddenDaoManager(this);
}

class HiddenDaoManager {
  final _$HiddenDaoMixin _db;
  HiddenDaoManager(this._db);
  $$HiddenCategoriesTableTableManager get hiddenCategories =>
      $$HiddenCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.hiddenCategories,
      );
  $$HiddenEntriesTableTableManager get hiddenEntries =>
      $$HiddenEntriesTableTableManager(_db.attachedDatabase, _db.hiddenEntries);
}
