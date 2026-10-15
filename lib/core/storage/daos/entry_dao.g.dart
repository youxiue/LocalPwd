// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_dao.dart';

// ignore_for_file: type=lint
mixin _$EntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $PasswordEntriesTable get passwordEntries => attachedDatabase.passwordEntries;
  $PasswordEntryCategoriesTable get passwordEntryCategories =>
      attachedDatabase.passwordEntryCategories;
  EntryDaoManager get managers => EntryDaoManager(this);
}

class EntryDaoManager {
  final _$EntryDaoMixin _db;
  EntryDaoManager(this._db);
  $$PasswordEntriesTableTableManager get passwordEntries =>
      $$PasswordEntriesTableTableManager(
        _db.attachedDatabase,
        _db.passwordEntries,
      );
  $$PasswordEntryCategoriesTableTableManager get passwordEntryCategories =>
      $$PasswordEntryCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.passwordEntryCategories,
      );
}
