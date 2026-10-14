import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes.dart';
import '../../../core/storage/database.dart';
import '../../../core/utils/app_notification.dart';
import '../controllers/home_controller.dart';
import '../../../widgets/category_sidebar.dart';
import '../../../widgets/entry_detail_sheet.dart';
import '../../../widgets/entry_list_item.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Obx(() => controller.isSearching.value
            ? TextField(
                controller: controller.searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索...',
                  border: InputBorder.none,
                ),
                onChanged: controller.onSearchChanged,
                onSubmitted: controller.onSearchSubmit,
              )
            : const Text('密码管理'),
        ),
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  controller.isSearching.value ? Icons.close : Icons.search,
                  size: 22,
                ),
                onPressed: controller.toggleSearch,
              )),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => controller.closeSearchIfEmpty(),
        child: Row(
          children: [
            Obx(() => CategorySidebar(
                  categories: controller.categories
                      .map((c) => SidebarCategory(
                            id: c.id,
                            name: c.name,
                            color: c.color,
                            icon: c.icon,
                          ))
                      .toList(),
                  selectedCategory: controller.selectedCategory.value,
                  onSelect: controller.selectCategory,
                  onAddCategory: () => unawaited(controller.showAddCategoryDialog()),
                )),
            Expanded(child: _buildEntryList()),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: () => Get.toNamed(AppRoutes.entryEdit),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEntryList() {
    return Obx(() {
      if (controller.entries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('暂无密码', style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: controller.entries.length,
          itemBuilder: (ctx, i) {
            final entry = controller.entries[i];
            return EntryListItem(
              entry: entry,
              username: controller.usernames[entry.id] ?? '',
              onTap: () => _showEntryDetail(entry),
              onEdit: () => Get.toNamed(AppRoutes.entryEdit, arguments: entry.id),
              onDelete: () => controller.deleteEntry(entry.id),
              onFavorite: () => controller.toggleFavorite(entry),
            );
          },
        ),
      );
    });
  }

  void _showEntryDetail(PasswordEntry entry) async {
    final detail = await controller.decryptEntry(entry);
    if (detail == null) {
      AppNotification.error('错误', '无法解密数据，请重新解锁');
      return;
    }
    unawaited(EntryDetailSheet.show(
      title: entry.title,
      detail: detail,
      onEdit: () => Get.toNamed(AppRoutes.entryEdit, arguments: entry.id),
      onDelete: () => controller.deleteEntry(entry.id),
      onCopy: controller.copyToClipboard,
    ));
  }
}
