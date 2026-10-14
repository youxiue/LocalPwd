import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:uuid/uuid.dart';

import '../../../app/routes.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/models/decrypted_entry.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/storage/database.dart';
import '../../../widgets/category_dialog.dart';

class HiddenController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _auth = AuthService.instance;
  final _crypto = CryptoService.instance;
  final _clipboard = ClipboardService.instance;
  final _uuid = const Uuid();

  final entries = <HiddenPasswordEntry>[].obs;
  final categories = <HiddenCategoryEntry>[].obs;
  final selectedCategory = Rxn<String?>(null);
  final titles = <String, String>{}.obs;
  final usernames = <String, String>{}.obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  Timer? _searchDebounce;
  StreamSubscription<List<HiddenPasswordEntry>>? _entrySub;
  StreamSubscription<List<HiddenCategoryEntry>>? _categorySub;
  List<HiddenPasswordEntry> _lastRows = const [];

  @override
  void onInit() {
    super.onInit();
    // 隐藏分类订阅流，分类增删改后自动同步
    _categorySub = _db.hiddenDao
        .watchAllCategories()
        .listen((rows) => categories.value = rows);
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
    unawaited(_onRows(_lastRows));
  }

  /// 用户输入时防抖搜索
  void onSearchChanged(String query) {
    if (query == searchQuery.value) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      searchQuery.value = query;
      unawaited(_onRows(_lastRows));
    });
  }

  @override
  void onClose() {
    _entrySub?.cancel();
    _categorySub?.cancel();
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    _resubscribe();
  }

  /// 按当前分类订阅隐藏条目流；数据变更自动刷新
  void _resubscribe() {
    _entrySub?.cancel();
    _entrySub = _db.hiddenDao
        .watchEntries(categoryId: selectedCategory.value)
        .listen((rows) => unawaited(_onRows(rows)));
  }

  /// 解密全部条目（标题/用户名都在加密体内），据此构建展示数据并按关键字过滤
  Future<void> _onRows(List<HiddenPasswordEntry> rows) async {
    _lastRows = rows;
    final key = _auth.hiddenSessionKey;
    if (key == null) {
      titles.value = {};
      usernames.value = {};
      entries.value = const [];
      return;
    }
    final decrypted = await Future.wait(rows.map((entry) async {
      try {
        return MapEntry<String, DecryptedEntry?>(
          entry.id,
          DecryptedEntry.fromJson(
            await _crypto.decryptJson(entry.encryptedData, key),
          ),
        );
      } catch (_) {
        return MapEntry<String, DecryptedEntry?>(entry.id, null);
      }
    }));

    final titleMap = <String, String>{};
    final userMap = <String, String>{};
    for (final pair in decrypted) {
      titleMap[pair.key] = pair.value?.title ?? '';
      userMap[pair.key] = pair.value?.username ?? '';
    }

    final query = searchQuery.value.trim().toLowerCase();
    final visible = query.isEmpty
        ? rows
        : rows
            .where((e) =>
                (titleMap[e.id] ?? '').toLowerCase().contains(query) ||
                (userMap[e.id] ?? '').toLowerCase().contains(query))
            .toList();

    titles.value = titleMap;
    usernames.value = userMap;
    entries.value = visible;
  }

  void selectCategory(String? id) {
    selectedCategory.value = id;
    _resubscribe();
  }

  Future<void> toggleFavorite(HiddenPasswordEntry entry) async {
    await _db.hiddenDao.toggleFavorite(entry.id, !entry.isFavorite);
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

    await _db.hiddenDao.deleteEntry(id);
  }

  Future<DecryptedEntry?> decryptEntry(HiddenPasswordEntry entry) async {
    final key = _auth.hiddenSessionKey;
    if (key == null) return null;
    try {
      return DecryptedEntry.fromJson(await _crypto.decryptJson(entry.encryptedData, key));
    } catch (_) {
      return null;
    }
  }

  Future<void> copyToClipboard(String text) async {
    await _clipboard.copy(text);
  }

  /// 弹出新增隐藏分类弹窗
  Future<void> showAddCategoryDialog() {
    return CategoryDialog.show(
      onSave: (name, color, icon) async {
        final id = _uuid.v4();
        final sortOrder = categories.length;
        await _db.hiddenDao.addCategory(
          HiddenCategoriesCompanion.insert(
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

  void exitHiddenMode() {
    _auth.exitHiddenMode();
    Get.back();
  }

  void gotoSettings() {
    Get.toNamed(AppRoutes.hiddenSettings);
  }

  @override
  Future<void> refresh() async {
    await loadData();
  }
}
