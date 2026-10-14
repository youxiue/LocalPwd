import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/models/decrypted_entry.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/storage/database.dart';
import '../../../app/routes.dart';
import '../../../widgets/category_dialog.dart';

class HomeController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _auth = AuthService.instance;
  final _crypto = CryptoService.instance;
  final _clipboard = ClipboardService.instance;
  final _uuid = const Uuid();

  final searchController = TextEditingController();

  final entries = <PasswordEntry>[].obs;
  final categories = <CategoryEntry>[].obs;
  final selectedCategory = Rxn<String?>(null);
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final usernames = <String, String>{}.obs;
  Timer? _searchDebounce;
  StreamSubscription<List<PasswordEntry>>? _entrySub;
  StreamSubscription<List<CategoryEntry>>? _categorySub;
  List<PasswordEntry> _lastRows = const [];

  /// 隐藏模式密码校验中标记，防止对话框在 Argon2id 校验期间被重复提交
  bool _verifyingHidden = false;

  @override
  void onInit() {
    super.onInit();
    // 分类侧边栏订阅流，分类增删改后自动同步
    _categorySub =
        _db.categoryDao.watchAll().listen((rows) => categories.value = rows);
    loadData();
  }

  /// 切换搜索框显示/隐藏
  void toggleSearch() {
    if (isSearching.value) {
      _closeSearch();
    } else {
      isSearching.value = true;
    }
  }

  /// 点击其他区域时，若搜索框为空则自动关闭搜索栏
  void closeSearchIfEmpty() {
    if (isSearching.value && searchController.text.isEmpty) {
      _closeSearch();
    }
  }

  void _closeSearch() {
    isSearching.value = false;
    _searchDebounce?.cancel();
    searchController.clear();
    searchQuery.value = '';
    unawaited(_onEntries(_lastRows));
  }

  /// 用户输入时防抖搜索（通过 TextField.onChanged 调用）
  void onSearchChanged(String query) {
    if (query == searchQuery.value) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      searchQuery.value = query;
      unawaited(_onEntries(_lastRows));
    });
  }

  /// 回车提交：检查是否为隐藏模式触发字符串
  void onSearchSubmit(String query) async {
    _searchDebounce?.cancel();
    if (query.isNotEmpty && await _auth.checkTriggerString(query)) {
      FocusManager.instance.primaryFocus?.unfocus();
      isSearching.value = false;
      searchController.clear();
      searchQuery.value = '';
      unawaited(_onEntries(_lastRows));
      await Future.delayed(const Duration(milliseconds: 50));
      _showHiddenPasswordDialog();
    }
  }

  Future<void> loadData() async {
    _resubscribe();
  }

  /// 按当前分类订阅条目流；数据变更自动刷新列表
  void _resubscribe() {
    _entrySub?.cancel();
    _entrySub = _db.entryDao
        .watchEntries(categoryId: selectedCategory.value)
        .listen((rows) => unawaited(_onEntries(rows)));
  }

  /// 解密用户名，并按关键字（标题 + 账号）在内存中过滤列表
  Future<void> _onEntries(List<PasswordEntry> rows) async {
    _lastRows = rows;
    final query = searchQuery.value.trim().toLowerCase();
    final key = _auth.sessionKey;
    if (key == null) {
      usernames.value = {};
      entries.value = query.isEmpty ? rows : const [];
      return;
    }
    final results = await Future.wait(rows.map((entry) async {
      try {
        final decrypted = DecryptedEntry.fromJson(
          await _crypto.decryptJson(entry.encryptedData, key),
        );
        return MapEntry(entry.id, decrypted.username);
      } catch (_) {
        return MapEntry(entry.id, '');
      }
    }));
    final map = <String, String>{};
    for (final result in results) {
      map[result.key] = result.value;
    }
    usernames.value = map;

    entries.value = query.isEmpty
        ? rows
        : rows
            .where((e) =>
                e.title.toLowerCase().contains(query) ||
                (map[e.id] ?? '').toLowerCase().contains(query))
            .toList();
  }

  void selectCategory(String? id) {
    selectedCategory.value = id;
    _resubscribe();
  }

  void _showHiddenPasswordDialog() {
    final pwdController = TextEditingController();
    final error = ''.obs;

    Get.defaultDialog(
      title: '验证',
      backgroundColor: Colors.white,
      content: Column(
        children: [
          const Text('请输入密码', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: pwdController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (_) => _verifyHidden(pwdController, error),
          ),
          const SizedBox(height: 8),
          Obx(() => error.value.isNotEmpty
              ? Text(error.value, style: const TextStyle(color: Colors.red, fontSize: 12))
              : const SizedBox.shrink()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => _verifyHidden(pwdController, error),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Future<void> _verifyHidden(TextEditingController ctrl, RxString error) async {
    // Argon2id 校验耗时较长，期间对话框仍可点击（回车与"确定"按钮是两个入口），
    // 必须防止重复调用：否则第二次 Get.back() 会把刚推入的隐藏页弹掉，
    // 导致隐藏页拿到的是绑定在旧路由上的控制器，旧路由销毁后 Get.find 抛 "not found"。
    if (_verifyingHidden) return;
    _verifyingHidden = true;
    error.value = '';
    try {
      final ok = await _auth.verifyHiddenPassword(ctrl.text.trim());
      if (!ok) {
        error.value = '密码错误';
        return;
      }
      Get.back();
      if (_auth.hiddenNeedsSetup) {
        _showHiddenSetupDialog();
      } else {
        Get.toNamed(AppRoutes.hidden);
      }
    } finally {
      _verifyingHidden = false;
    }
  }

  void _showHiddenSetupDialog() {
    final triggerCtrl = TextEditingController(text: AppConstants.defaultTriggerString);
    final pwdCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final error = ''.obs;
    // 防止重复提交：setupHiddenMode 内含 Argon2id，耗时较长，期间按钮仍可点击
    var saving = false;

    Get.defaultDialog(
      title: '配置隐藏模式',
      backgroundColor: Colors.white,
      barrierDismissible: false,
      content: Column(
        children: [
          const Text('请修改默认配置', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: triggerCtrl,
            decoration: const InputDecoration(
              labelText: '触发字符串',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: pwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '新密码',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '确认密码',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => error.value.isNotEmpty
              ? Text(error.value, style: const TextStyle(color: Colors.red, fontSize: 12))
              : const SizedBox.shrink()),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            if (saving) return;
            final trigger = triggerCtrl.text.trim();
            final pwd = pwdCtrl.text.trim();
            final confirm = confirmCtrl.text.trim();

            if (trigger.isEmpty || pwd.isEmpty) {
              error.value = '不能为空';
              return;
            }
            if (pwd.length < 6) {
              error.value = '密码至少 6 位';
              return;
            }
            if (pwd != confirm) {
              error.value = '两次密码不一致';
              return;
            }

            saving = true;
            await _auth.setupHiddenMode(trigger, pwd);
            Get.back();
            Get.toNamed(AppRoutes.hidden);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> toggleFavorite(PasswordEntry entry) async {
    await _db.entryDao.toggleFavorite(entry.id, !entry.isFavorite);
  }

  Future<void> deleteEntry(String id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除这条密码记录吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _db.entryDao.deleteEntry(id);
  }

  /// 解密条目数据
  Future<DecryptedEntry?> decryptEntry(PasswordEntry entry) async {
    final key = _auth.sessionKey;
    if (key == null) return null;
    try {
      return DecryptedEntry.fromJson(await _crypto.decryptJson(entry.encryptedData, key));
    } catch (_) {
      return null;
    }
  }

  /// 复制到剪贴板（30 秒后自动清除）
  Future<void> copyToClipboard(String text) async {
    await _clipboard.copy(text);
  }

  /// 在首页直接弹出新增分类弹窗
  Future<void> showAddCategoryDialog() {
    return CategoryDialog.show(
      onSave: (name, color, icon) async {
        final id = _uuid.v4();
        final sortOrder = categories.length;
        await _db.categoryDao.addCategory(
          CategoriesCompanion.insert(
            id: id,
            name: name,
            color: Value(color),
            icon: Value(icon),
            sortOrder: Value(sortOrder),
          ),
        );
      },
    );
  }

  @override
  Future<void> refresh() async {
    await loadData();
  }

  @override
  void onClose() {
    _entrySub?.cancel();
    _categorySub?.cancel();
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
