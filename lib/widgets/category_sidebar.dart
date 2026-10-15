import 'package:flutter/material.dart';

import '../core/utils/icon_mapper.dart';

/// 分类侧边栏条目数据（首页与隐藏模式共用）
class SidebarCategory {
  const SidebarCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String color;
  final String icon;
}

/// 首页 / 隐藏模式共用的分类侧边栏
///
/// 调用方需自行用 Obx 包裹，以便分类或选中项变化时刷新。
class CategorySidebar extends StatelessWidget {
  const CategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
    required this.onAddCategory,
  });

  final List<SidebarCategory> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 72,
      color: Colors.white,
      child: ListView(
        // 底部预留安全区 + 固定间距，避免分类过多时添加按钮贴底难点击
        padding: EdgeInsets.only(
          top: 4,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          _buildItem(
            icon: Icons.apps,
            label: '全部',
            color: primary,
            isSelected: selectedCategory == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map((cat) => _buildItem(
                icon: iconFromString(cat.icon),
                label: cat.name,
                color: hexToColor(cat.color),
                isSelected: selectedCategory == cat.id,
                onTap: () => onSelect(cat.id),
              )),
          // 添加分类按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Icon(Icons.add, color: Colors.grey, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? color : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
