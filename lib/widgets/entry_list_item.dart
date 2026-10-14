import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/storage/database.dart';

/// 可滑动操作的密码列表项
/// 左滑：收藏 / 编辑 / 删除
class EntryListItem extends StatelessWidget {
  final PasswordEntry entry;
  final String username;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  const EntryListItem({
    super.key,
    required this.entry,
    required this.username,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.75,
        children: [
          SlidableAction(
            onPressed: (_) => onFavorite(),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            icon: entry.isFavorite ? Icons.star : Icons.star_border,
          ),
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
          ),
        ],
      ),
      child: ListTile(
        title: Text(entry.title),
        subtitle: Text(
          username,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: entry.isFavorite
            ? const Icon(Icons.star, color: Colors.amber, size: 18)
            : null,
        onTap: onTap,
      ),
    );
  }
}
