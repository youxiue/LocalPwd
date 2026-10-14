import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:uuid/uuid.dart';

import '../../../core/storage/database.dart';
import '../../../widgets/category_dialog.dart';

class CategoryController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _uuid = const Uuid();

  final categories = <CategoryEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    categories.value = await _db.categoryDao.getAll();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final list = categories.toList();
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    categories.value = list;
    await _db.categoryDao.updateSortOrder(list.map((e) => e.id).toList());
  }

  Future<void> _addCategory(String name, String color, String icon) async {
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
    await _load();
  }

  Future<void> _updateCategory(
      String id, String name, String color, String icon) async {
    await _db.categoryDao.updateCategory(
      CategoriesCompanion(
        id: Value(id),
        name: Value(name),
        color: Value(color),
        icon: Value(icon),
      ),
    );
    await _load();
  }

  void showEditDialog({CategoryEntry? existing}) {
    unawaited(CategoryDialog.show(
      title: existing == null ? '新建分类' : '编辑分类',
      initialName: existing?.name,
      initialColor: existing?.color,
      initialIcon: existing?.icon,
      onSave: (name, color, icon) async {
        if (existing == null) {
          await _addCategory(name, color, icon);
        } else {
          await _updateCategory(existing.id, name, color, icon);
        }
      },
    ));
  }

  void confirmDelete(CategoryEntry category) {
    Get.defaultDialog(
      title: '删除分类',
      backgroundColor: Colors.white,
      content: Text('确认删除"${category.name}"？\n该分类下的密码将变为"无分类"'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('取消')),
        FilledButton(
          onPressed: () async {
            await _db.categoryDao.deleteCategory(category.id);
            await _load();
            Get.back();
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('删除'),
        ),
      ],
    );
  }
}
