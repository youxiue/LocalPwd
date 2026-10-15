import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/models/decrypted_entry.dart';
import 'detail_row.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// 条目详情底部弹窗（首页与隐藏模式共用）
///
/// 编辑 / 删除前会自动关闭弹窗，回调内无需再调用 [Get.back]。
class EntryDetailSheet extends StatefulWidget {
  const EntryDetailSheet({
    super.key,
    required this.title,
    required this.detail,
    required this.updatedAt,
    required this.isFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onCopy,
  });

  final String title;
  final DecryptedEntry detail;
  final DateTime updatedAt;
  final bool isFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  /// 传入切换后的目标收藏状态，避免依赖弹窗外的陈旧数据
  final ValueChanged<bool> onToggleFavorite;
  final ValueChanged<String> onCopy;

  /// 弹出详情弹窗，返回弹窗关闭后完成的 Future
  static Future<void> show({
    required String title,
    required DecryptedEntry detail,
    required DateTime updatedAt,
    required bool isFavorite,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required ValueChanged<bool> onToggleFavorite,
    required ValueChanged<String> onCopy,
  }) async {
    await Get.bottomSheet<void>(
      EntryDetailSheet(
        title: title,
        detail: detail,
        updatedAt: updatedAt,
        isFavorite: isFavorite,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleFavorite: onToggleFavorite,
        onCopy: onCopy,
      ),
      isScrollControlled: true,
    );
  }

  @override
  State<EntryDetailSheet> createState() => _EntryDetailSheetState();
}

class _EntryDetailSheetState extends State<EntryDetailSheet> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = widget.updatedAt;
    final updatedText =
        '${updatedAt.year}-${_two(updatedAt.month)}-${_two(updatedAt.day)} '
        '${_two(updatedAt.hour)}:${_two(updatedAt.minute)}';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  onPressed: () {
                    Get.back();
                    widget.onEdit();
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    size: 22,
                    color: _isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    final next = !_isFavorite;
                    setState(() => _isFavorite = next);
                    widget.onToggleFavorite(next);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
                  onPressed: () {
                    Get.back();
                    widget.onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.detail.username.isNotEmpty)
                      _row(Icons.person_outline, '用户名', widget.detail.username),
                    if (widget.detail.password.isNotEmpty)
                      _row(Icons.lock_outline, '密码', '••••••••',
                          masked: widget.detail.password),
                    if (widget.detail.url.isNotEmpty)
                      _row(Icons.link, '网址', widget.detail.url),
                    if (widget.detail.notes.isNotEmpty)
                      _row(Icons.notes, '备注', widget.detail.notes),
                    ...widget.detail.customFields
                        .map((f) => _row(Icons.label_outline, f.key, f.value)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '最后修改：$updatedText',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {String? masked}) {
    return DetailRow(
      icon: icon,
      label: label,
      value: value,
      secretValue: masked,
      onCopy: widget.onCopy,
    );
  }
}
