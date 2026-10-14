import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import '../../../app/routes.dart';
import '../../../core/storage/database.dart';
import '../../../core/utils/app_notification.dart';
import '../controllers/hidden_controller.dart';
import '../../../widgets/category_sidebar.dart';
import '../../../widgets/entry_detail_sheet.dart';

class HiddenHomeView extends GetView<HiddenController> {
  const HiddenHomeView({super.key});

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
              )
            : const Text('隐藏模式'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.exitHiddenMode,
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
            onPressed: controller.gotoSettings,
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
          onPressed: () => Get.toNamed(AppRoutes.hiddenEntryEdit),
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
              Icon(Icons.visibility_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('暂无隐藏条目', style: TextStyle(color: Colors.grey.shade400)),
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
            return Slidable(
              key: ValueKey(entry.id),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.75,
                children: [
                  SlidableAction(
                    onPressed: (_) => controller.toggleFavorite(entry),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    icon: entry.isFavorite ? Icons.star : Icons.star_border,
                  ),
                  SlidableAction(
                    onPressed: (_) => Get.toNamed(AppRoutes.hiddenEntryEdit,
                        arguments: entry.id),
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.edit_outlined,
                  ),
                  SlidableAction(
                    onPressed: (_) => controller.deleteEntry(entry.id),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                  ),
                ],
              ),
              child: ListTile(
                title: Text(controller.titles[entry.id] ?? ''),
                subtitle: Text(
                  controller.usernames[entry.id] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: entry.isFavorite
                    ? const Icon(Icons.star, color: Colors.amber, size: 18)
                    : null,
                onTap: () => _showDetail(entry),
              ),
            );
          },
        ),
      );
    });
  }

  void _showDetail(HiddenPasswordEntry entry) async {
    final detail = await controller.decryptEntry(entry);
    if (detail == null) {
      AppNotification.error('错误', '无法解密数据，请重新进入隐藏模式');
      return;
    }
    unawaited(EntryDetailSheet.show(
      title: controller.titles[entry.id] ?? '',
      detail: detail,
      onEdit: () => Get.toNamed(AppRoutes.hiddenEntryEdit, arguments: entry.id),
      onDelete: () => controller.deleteEntry(entry.id),
      onCopy: controller.copyToClipboard,
    ));
  }
}
