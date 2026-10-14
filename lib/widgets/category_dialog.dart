import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/category_presets.dart';
import '../core/utils/app_notification.dart';
import '../core/utils/icon_mapper.dart';

/// 新建 / 编辑分类弹窗（侧边栏、普通分类管理、隐藏分类管理共用）。
/// 保存逻辑由 [onSave] 注入：普通模式写 categoryDao，隐藏模式写 hiddenDao。
class CategoryDialog extends StatefulWidget {
  const CategoryDialog({
    super.key,
    required this.title,
    required this.initialName,
    required this.initialColor,
    required this.initialIcon,
    required this.onSave,
  });

  final String title;
  final String initialName;
  final String initialColor;
  final String initialIcon;
  final Future<void> Function(String name, String color, String icon) onSave;

  /// 弹出弹窗；[initialName]/[initialColor]/[initialIcon] 用于编辑已有分类
  static Future<void> show({
    String title = '新建分类',
    String? initialName,
    String? initialColor,
    String? initialIcon,
    required Future<void> Function(String name, String color, String icon)
    onSave,
  }) {
    return showDialog<void>(
      context: Get.context!,
      builder: (ctx) => CategoryDialog(
        title: title,
        initialName: initialName ?? '',
        initialColor: initialColor ?? CategoryPresets.colors[5],
        initialIcon: initialIcon ?? CategoryPresets.icons[0],
        onSave: onSave,
      ),
    );
  }

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController nameCtrl;
  late String color;
  late String icon;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName);
    color = widget.initialColor;
    icon = widget.initialIcon;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: 90,
          left: 24,
          right: 24,
          bottom: bottomInset,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          elevation: 6,
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '颜色',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxWidth = constraints.maxWidth;
                      const double itemSize = 32.0;
                      const double minSpacing = 10.0; // 最小间距，也是你原来的 spacing
                      const double runSpacing = 10.0; // 行间距保持不变

                      // 计算一行最多能放几个，同时保证间距 >= minSpacing
                      // 不等式：n * itemSize + (n - 1) * minSpacing <= maxWidth
                      // 解得：n <= (maxWidth + minSpacing) / (itemSize + minSpacing)
                      int itemsPerRow =
                          ((maxWidth + minSpacing) / (itemSize + minSpacing))
                              .floor();
                      if (itemsPerRow < 1) itemsPerRow = 1;

                      double spacing;
                      if (itemsPerRow == 1) {
                        spacing = 0; // 一行只有一个，直接贴左
                      } else {
                        // 让 itemsPerRow 个元素加上 (itemsPerRow - 1) 个间距刚好等于 maxWidth
                        // 这样左右边距都为 0，且元素均匀分布
                        spacing =
                            (maxWidth - itemsPerRow * itemSize) /
                            (itemsPerRow - 1);
                        // 减去极小值，防止浮点误差导致一行放不下
                        spacing -= 0.01;
                        // 理论上 spacing 一定 >= minSpacing，但保险起见再判断一次
                        if (spacing < minSpacing) spacing = minSpacing;
                      }

                      return Wrap(
                        alignment: WrapAlignment.start, // 左对齐，最后一行自然保持相同间距
                        spacing: spacing,
                        runSpacing: runSpacing,
                        children: CategoryPresets.colors.map((c) {
                          final selected = c == color;
                          return GestureDetector(
                            onTap: () => setState(() => color = c),
                            child: Container(
                              width: itemSize,
                              height: itemSize,
                              decoration: BoxDecoration(
                                color: hexToColor(c),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(color: Colors.black, width: 3)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '图标',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxWidth = constraints.maxWidth;
                      const double itemSize = 32.0;
                      const double minSpacing = 10.0; // 最小间距，也是你原来的 spacing
                      const double runSpacing = 10.0; // 行间距保持不变

                      // 计算一行最多能放几个，同时保证间距 >= minSpacing
                      // n * itemSize + (n - 1) * minSpacing <= maxWidth
                      int itemsPerRow =
                          ((maxWidth + minSpacing) / (itemSize + minSpacing))
                              .floor();
                      if (itemsPerRow < 1) itemsPerRow = 1;

                      double spacing;
                      if (itemsPerRow == 1) {
                        spacing = 0; // 一行只有一个，直接贴左
                      } else {
                        // 让 itemsPerRow 个元素加上 (itemsPerRow - 1) 个间距刚好等于 maxWidth
                        // 左右贴边，元素均匀分布
                        spacing =
                            (maxWidth - itemsPerRow * itemSize) /
                            (itemsPerRow - 1);
                        spacing -= 0.01; // 防止浮点误差导致一行放不下
                        if (spacing < minSpacing) spacing = minSpacing;
                      }

                      return Wrap(
                        alignment: WrapAlignment.start, // 左对齐，最后一行自然保持相同间距
                        spacing: spacing,
                        runSpacing: runSpacing,
                        children: CategoryPresets.icons.map((ic) {
                          final selected = ic == icon;
                          return GestureDetector(
                            onTap: () => setState(() => icon = ic),
                            child: Container(
                              width: itemSize,
                              height: itemSize,
                              decoration: BoxDecoration(
                                color: selected
                                    ? hexToColor(color)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                iconFromString(ic),
                                size: 18,
                                color: selected ? Colors.white : Colors.black54,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: Get.back, child: const Text('取消')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            AppNotification.info('提示', '请输入名称');
                            return;
                          }
                          await widget.onSave(name, color, icon);
                          Get.back();
                        },
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
