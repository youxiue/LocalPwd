import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../crypto/crypto_service.dart';
import '../storage/database.dart';

/// 导出服务：加密 JSON 导出/导入
/// 使用导出密码加密，支持跨设备迁移
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// 当前支持的备份格式版本
  /// v3：条目分类改为 categoryIds 多选列表（v1/v2 为单分类 categoryId）
  static const int supportedVersion = 3;

  final _crypto = CryptoService.instance;

  /// 导出为加密 JSON 文件
  /// [sessionKey] 当前会话密钥，用于解密原始数据
  /// [exportPassword] 用户输入的导出密码，用于加密备份
  /// [isHidden] = true 时导出隐藏模式数据
  Future<String> exportToFile({
    required AppDatabase db,
    required SecretKey sessionKey,
    required String exportPassword,
    bool isHidden = false,
  }) async {
    // 1. 生成导出用盐和密钥
    final salt = await _crypto.generateSalt();
    final exportKey = await _crypto.deriveKey(exportPassword, salt);

    // 2. 构建导出数据（解密原始数据）
    final exportData = await _buildExportData(
      db: db,
      sessionKey: sessionKey,
      isHidden: isHidden,
    );

    // 3. 加密
    final encrypted = await _crypto.encryptJson(exportData, exportKey);

    // 4. 组装：salt + ":" + encrypted
    final envelope = '${base64Encode(salt)}:$encrypted';

    // 5. 写入文件
    final dir = await getApplicationDocumentsDirectory();
    final fileName = isHidden ? 'hidden_backup.enc' : 'password_backup.enc';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(envelope);
    return file.path;
  }

  /// 删除导出产生的临时备份文件（分享完成或取消后调用）
  Future<void> deleteExportFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 删除失败不影响主流程
    }
  }

  Future<Map<String, dynamic>> _buildExportData({
    required AppDatabase db,
    required SecretKey sessionKey,
    required bool isHidden,
  }) async {
    if (isHidden) {
      final entries = await db.hiddenDao.getAllEntries();
      final categories = await db.hiddenDao.getAllCategories();
      final links = await db.hiddenDao.allEntryCategoryLinks();
      return {
        'version': supportedVersion,
        'type': 'hidden',
        'exportedAt': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => {
          'id': c.id,
          'name': c.name,
          'color': c.color,
          'icon': c.icon,
          'sortOrder': c.sortOrder,
        }).toList(),
        'entries': await _decryptEntriesForExport(
          entries: entries,
          sessionKey: sessionKey,
          titleFromColumn: false,
          links: links,
        ),
      };
    } else {
      final entries = await db.entryDao.getAllEntries();
      final categories = await db.categoryDao.getAll();
      final links = await db.entryDao.allEntryCategoryLinks();
      return {
        'version': supportedVersion,
        'type': 'normal',
        'exportedAt': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => {
          'id': c.id,
          'name': c.name,
          'color': c.color,
          'icon': c.icon,
          'sortOrder': c.sortOrder,
        }).toList(),
        'entries': await _decryptEntriesForExport(
          entries: entries,
          sessionKey: sessionKey,
          titleFromColumn: true,
          links: links,
        ),
      };
    }
  }

  /// 解密每个条目的加密数据，导出明文
  /// [titleFromColumn] 为 true 时标题取自明文列（普通模式）；
  /// 为 false 时标题取自解密结果（隐藏模式，标题已加密入库）
  Future<List<Map<String, dynamic>>> _decryptEntriesForExport({
    required List entries,
    required SecretKey sessionKey,
    required bool titleFromColumn,
    required Map<String, List<String>> links,
  }) async {
    final result = <Map<String, dynamic>>[];
    for (final entry in entries) {
      try {
        final decrypted = await _crypto.decryptJson(entry.encryptedData, sessionKey);
        final title = titleFromColumn
            ? entry.title as String
            : decrypted['title'] as String? ?? '';
        result.add({
          'id': entry.id,
          'title': title,
          'categoryIds': links[entry.id] ?? const <String>[],
          'decryptedData': decrypted,
          'isFavorite': entry.isFavorite,
          'createdAt': entry.createdAt.toIso8601String(),
          'updatedAt': entry.updatedAt.toIso8601String(),
        });
      } catch (_) {
        // 跳过无法解密的条目
      }
    }
    return result;
  }

  /// 从加密 JSON 文件导入
  /// [sessionKey] 当前会话密钥，用于重新加密数据
  /// [importPassword] 导出时设置的密码
  Future<void> importFromFile({
    required String filePath,
    required AppDatabase db,
    required SecretKey sessionKey,
    required String importPassword,
    required bool isHidden,
  }) async {
    final file = File(filePath);
    final content = await file.readAsString();

    // 1. 解析信封：salt:encrypted
    final colonIdx = content.indexOf(':');
    if (colonIdx < 0) throw Exception('文件格式错误');
    final salt = Uint8List.fromList(base64Decode(content.substring(0, colonIdx)));
    final encrypted = content.substring(colonIdx + 1);

    // 2. 派生密钥并解密
    final importKey = await _crypto.deriveKey(importPassword, salt);
    final data = await _crypto.decryptJson(encrypted, importKey);

    // 3. 校验备份类型与版本，避免普通/隐藏备份互导或未来格式静默失败
    final expectedType = isHidden ? 'hidden' : 'normal';
    if (data['type'] != expectedType) {
      throw Exception(isHidden ? '这不是隐藏模式备份文件' : '这不是普通模式备份文件');
    }
    final version = data['version'];
    if (version is! int || version < 1 || version > supportedVersion) {
      throw Exception('备份文件版本不受支持');
    }

    // 4. 重新加密并写入数据库
    if (isHidden) {
      await _importHidden(db: db, data: data, sessionKey: sessionKey);
    } else {
      await _importNormal(db: db, data: data, sessionKey: sessionKey);
    }
  }

  Future<void> _importNormal({
    required AppDatabase db,
    required Map<String, dynamic> data,
    required SecretKey sessionKey,
  }) async {
    await db.transaction(() async {
      final categories = data['categories'] as List? ?? [];
      for (final c in categories) {
        final m = c as Map<String, dynamic>;
        await db.into(db.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: m['id'] as String,
            name: m['name'] as String,
            color: Value(m['color'] as String? ?? '#2196F3'),
            icon: Value(m['icon'] as String? ?? 'folder'),
            sortOrder: Value(m['sortOrder'] as int? ?? 0),
          ),
        );
      }

      final entries = data['entries'] as List? ?? [];
      for (final e in entries) {
        final m = e as Map<String, dynamic>;
        final decryptedData = m['decryptedData'];
        if (decryptedData is! Map<String, dynamic>) continue;
        final reEncrypted = await _crypto.encryptJson(decryptedData, sessionKey);
        await db.into(db.passwordEntries).insertOnConflictUpdate(
          PasswordEntriesCompanion.insert(
            id: m['id'] as String,
            title: m['title'] as String,
            encryptedData: reEncrypted,
            isFavorite: Value(m['isFavorite'] as bool? ?? false),
          ),
        );
        await db.entryDao.setEntryCategories(
          m['id'] as String,
          _categoryIdsOf(m),
        );
      }
    });
  }

  Future<void> _importHidden({
    required AppDatabase db,
    required Map<String, dynamic> data,
    required SecretKey sessionKey,
  }) async {
    await db.transaction(() async {
      final categories = data['categories'] as List? ?? [];
      for (final c in categories) {
        final m = c as Map<String, dynamic>;
        await db.into(db.hiddenCategories).insertOnConflictUpdate(
          HiddenCategoriesCompanion.insert(
            id: m['id'] as String,
            name: m['name'] as String,
            color: Value(m['color'] as String? ?? '#424242'),
            icon: Value(m['icon'] as String? ?? 'visibility_off'),
            sortOrder: Value(m['sortOrder'] as int? ?? 0),
          ),
        );
      }

      final entries = data['entries'] as List? ?? [];
      for (final e in entries) {
        final m = e as Map<String, dynamic>;
        final decryptedData = m['decryptedData'];
        if (decryptedData is! Map<String, dynamic>) continue;
        // 标题并入加密体；兼容旧备份（标题原本在顶层）
        final payload = Map<String, dynamic>.from(decryptedData);
        if ((payload['title'] as String?)?.isNotEmpty != true) {
          payload['title'] = m['title'];
        }
        final reEncrypted = await _crypto.encryptJson(payload, sessionKey);
        await db.into(db.hiddenEntries).insertOnConflictUpdate(
          HiddenEntriesCompanion.insert(
            id: m['id'] as String,
            encryptedData: reEncrypted,
            isFavorite: Value(m['isFavorite'] as bool? ?? false),
          ),
        );
        await db.hiddenDao.setEntryCategories(
          m['id'] as String,
          _categoryIdsOf(m),
        );
      }
    });
  }

  /// 解析条目的分类 ID 列表；兼容旧版备份的单分类 categoryId 字段
  static List<String> _categoryIdsOf(Map<String, dynamic> m) {
    final ids = m['categoryIds'];
    if (ids is List) {
      return ids.whereType<String>().toList();
    }
    final legacy = m['categoryId'];
    return legacy is String ? [legacy] : const <String>[];
  }
}
