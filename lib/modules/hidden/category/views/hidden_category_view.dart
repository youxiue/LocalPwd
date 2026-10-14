import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/icon_mapper.dart';
import '../controllers/hidden_category_controller.dart';

class HiddenCategoryView extends GetView<HiddenCategoryController> {
  const HiddenCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => controller.showEditDialog(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('暂无分类', style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }
        return ReorderableListView.builder(
          itemCount: controller.categories.length,
          onReorder: controller.reorder,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (ctx, i) {
            final cat = controller.categories[i];
            return ListTile(
              key: ValueKey(cat.id),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hexToColor(cat.color),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconFromString(cat.icon), color: Colors.white, size: 20),
              ),
              title: Text(cat.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => controller.showEditDialog(existing: cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => controller.confirmDelete(cat),
                  ),
                  const Icon(Icons.drag_handle, color: Colors.grey),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
