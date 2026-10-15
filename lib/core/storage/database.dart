import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/crypto_service.dart';
import '../services/auth_service.dart';
import 'tables/categories.dart';
import 'tables/password_entries.dart';
import 'tables/hidden_tables.dart';
import 'tables/entry_category_links.dart';
import 'daos/entry_dao.dart';
import 'daos/category_dao.dart';
import 'daos/hidden_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    PasswordEntries,
    HiddenCategories,
    HiddenEntries,
    PasswordEntryCategories,
    HiddenEntryCategories,
  ],
  daos: [EntryDao, CategoryDao, HiddenDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2：隐藏条目标题并入加密体，移除 title 明文列。
            // 用 alterTable 重建隐藏条目表并按同名列搬运数据，保留既有行。
            await m.alterTable(TableMigration(hiddenEntries));
          }
          if (from < 3) {
            // v3：单分类列改为多对多关联表，支持一个条目属于多个分类。
            // 先建关联表并搬运旧数据，再重建条目表移除 category_id 列。
            await m.createTable(passwordEntryCategories);
            await m.createTable(hiddenEntryCategories);
            await customStatement(
              'INSERT INTO password_entry_categories (entry_id, category_id) '
              'SELECT id, category_id FROM password_entries '
              'WHERE category_id IS NOT NULL',
            );
            await customStatement(
              'INSERT INTO hidden_entry_categories (entry_id, category_id) '
              'SELECT id, category_id FROM hidden_entries '
              'WHERE category_id IS NOT NULL',
            );
            await m.alterTable(TableMigration(passwordEntries));
            await m.alterTable(TableMigration(hiddenEntries));
          }
        },
      );

  /// 使用 SQLCipher 加密的数据库连接
  /// LazyDatabase 延迟首次查询，此时用户已解锁，DEK 可用
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'local_pwd.db'));

      // 从 AuthService 获取 DEK，用其 base64 作为 SQLCipher 密钥
      // DEK 不随密码变更而改变（只改 KEK），数据库无需 re-key
      final dek = AuthService.instance.sessionKey;
      if (dek == null) {
        throw StateError('DEK not available: user must unlock first');
      }
      final dekBytes = await CryptoService.instance.extractKeyBytes(dek);
      final dbPassword = base64Encode(dekBytes);

      return NativeDatabase(
        file,
        setup: (db) {
          db.execute("PRAGMA key = '$dbPassword';");
        },
      );
    });
  }
}
