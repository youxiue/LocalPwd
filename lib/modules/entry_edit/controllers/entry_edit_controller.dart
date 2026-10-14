import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:uuid/uuid.dart';

import '../../../app/routes.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/models/decrypted_entry.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/password_generator_service.dart';
import '../../../core/storage/database.dart';
import '../../../core/utils/app_notification.dart';

/// 分类下拉选项 — 普通/隐藏模式通用（字段相同，避免依赖具体表类型）
class EntryCategoryOption {
  final String id;
  final String name;

  const EntryCategoryOption({required this.id, required this.name});
}

/// 新增/编辑密码条目的共享逻辑基类。
///
/// 普通模式（[EntryEditController]）与隐藏模式（HiddenEntryEditController）
/// 复用全部表单状态、加解密与保存流程，仅通过少量抽象成员提供差异：
/// 会话密钥、分类加载、原始条目读取与写库。
abstract class EntryEditControllerBase extends GetxController {
  final _crypto = CryptoService.instance;
  final _uuid = const Uuid();
  final _generator = PasswordGeneratorService.instance;

  final titleController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final urlController = TextEditingController();
  final notesController = TextEditingController();

  final categories = <EntryCategoryOption>[].obs;
  final selectedCategoryId = Rxn<String?>(null);
  final customFields = <CustomField>[].obs;
  final isEditing = false.obs;
  final isObscure = true.obs;
  final passwordStrength = (-1).obs; // -1 = 未输入

  String? entryId;

  // ---- 差异点（子类实现）----

  /// 当前模式的会话密钥；为 null 时应跳转解锁页
  SecretKey? get sessionKey;

  /// 加载当前模式的分类列表
  Future<List<EntryCategoryOption>> loadCategories();

  /// 读取待编辑条目的原始（未解密）数据；不存在时返回 null。
  /// [title] 为 null 表示标题存在加密体内（隐藏模式），由解密结果回填。
  Future<({String? title, String? categoryId, String encryptedData})?>
      loadRawEntry(String id);

  /// 写库：新增或更新由 [isNew] 区分
  Future<void> persistEntry({
    required String id,
    required bool isNew,
    required String title,
    required String? categoryId,
    required String encryptedData,
  });

  @override
  void onInit() {
    super.onInit();
    entryId = Get.arguments as String?;
    passwordController.addListener(_updateStrength);
    _init();
  }

  void _updateStrength() {
    final pwd = passwordController.text;
    passwordStrength.value = pwd.isEmpty ? -1 : _generator.strength(pwd);
  }

  Future<void> _init() async {
    categories.value = await loadCategories();

    if (entryId != null) {
      final raw = await loadRawEntry(entryId!);
      if (raw != null) {
        final key = sessionKey;
        if (key == null) {
          Get.offAllNamed(AppRoutes.unlock);
          return;
        }
        isEditing.value = true;
        selectedCategoryId.value = raw.categoryId;

        try {
          final decrypted = DecryptedEntry.fromJson(
            await _crypto.decryptJson(raw.encryptedData, key),
          );
          titleController.text = raw.title ?? decrypted.title;
          usernameController.text = decrypted.username;
          passwordController.text = decrypted.password;
          urlController.text = decrypted.url;
          notesController.text = decrypted.notes;
          customFields.value = decrypted.customFields
              .map((f) => CustomField(key: f.key, value: f.value))
              .toList();
          _updateStrength();
        } catch (_) {
          AppNotification.error('错误', '数据解密失败');
        }
      }
    }
  }

  void addCustomField() {
    customFields.add(CustomField(key: '', value: ''));
  }

  void removeCustomField(int index) {
    if (index >= 0 && index < customFields.length) {
      customFields.removeAt(index);
    }
  }

  void toggleObscure() => isObscure.value = !isObscure.value;

  void selectCategory(String? id) {
    selectedCategoryId.value = id;
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      AppNotification.info('提示', '请输入标题');
      return;
    }

    final decrypted = DecryptedEntry(
      title: title,
      username: usernameController.text.trim(),
      password: passwordController.text,
      url: urlController.text.trim(),
      notes: notesController.text.trim(),
      customFields: customFields
          .where((f) => f.key.trim().isNotEmpty)
          .map((f) => CustomField(key: f.key.trim(), value: f.value.trim()))
          .toList(),
    );

    final key = sessionKey;
    if (key == null) {
      Get.offAllNamed(AppRoutes.unlock);
      return;
    }
    final encrypted = await _crypto.encryptJson(decrypted.toJson(), key);

    final isUpdate = isEditing.value && entryId != null;
    await persistEntry(
      id: isUpdate ? entryId! : _uuid.v4(),
      isNew: !isUpdate,
      title: title,
      categoryId: selectedCategoryId.value,
      encryptedData: encrypted,
    );

    Get.back();
  }

  @override
  void onClose() {
    passwordController.removeListener(_updateStrength);
    titleController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    urlController.dispose();
    notesController.dispose();
    super.onClose();
  }
}

/// 普通模式条目编辑控制器
class EntryEditController extends EntryEditControllerBase {
  final _db = Get.find<AppDatabase>();

  @override
  SecretKey? get sessionKey => AuthService.instance.sessionKey;

  @override
  Future<List<EntryCategoryOption>> loadCategories() async {
    final list = await _db.categoryDao.getAll();
    return list
        .map((c) => EntryCategoryOption(id: c.id, name: c.name))
        .toList();
  }

  @override
  Future<({String title, String? categoryId, String encryptedData})?>
      loadRawEntry(String id) async {
    final entry = await _db.entryDao.getById(id);
    if (entry == null) return null;
    return (
      title: entry.title,
      categoryId: entry.categoryId,
      encryptedData: entry.encryptedData,
    );
  }

  @override
  Future<void> persistEntry({
    required String id,
    required bool isNew,
    required String title,
    required String? categoryId,
    required String encryptedData,
  }) async {
    if (isNew) {
      await _db.entryDao.addEntry(
        PasswordEntriesCompanion.insert(
          id: id,
          title: title,
          categoryId: Value(categoryId),
          encryptedData: encryptedData,
        ),
      );
    } else {
      await _db.entryDao.updateEntry(
        PasswordEntriesCompanion(
          id: Value(id),
          title: Value(title),
          categoryId: Value(categoryId),
          encryptedData: Value(encryptedData),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}
