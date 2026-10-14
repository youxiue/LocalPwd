import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/models/decrypted_entry.dart';
import 'detail_row.dart';

/// 条目详情底部弹窗（首页与隐藏模式共用）
///
/// 编辑 / 删除前会自动关闭弹窗，回调内无需再调用 [Get.back]。
class EntryDetailSheet extends StatelessWidget {
  const EntryDetailSheet({
    super.key,
    required this.title,
    required this.detail,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });

  final String title;
  final DecryptedEntry detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onCopy;

  /// 弹出详情弹窗，返回弹窗关闭后完成的 Future
  static Future<void> show({
    required String title,
    required DecryptedEntry detail,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required ValueChanged<String> onCopy,
  }) async {
    await Get.bottomSheet<void>(
      EntryDetailSheet(
        title: title,
        detail: detail,
        onEdit: onEdit,
        onDelete: onDelete,
        onCopy: onCopy,
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Text(title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  onPressed: () {
                    Get.back();
                    onEdit();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
                  onPressed: () {
                    Get.back();
                    onDelete();
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
                    if (detail.username.isNotEmpty)
                      _row(Icons.person_outline, '用户名', detail.username),
                    if (detail.password.isNotEmpty)
                      _row(Icons.lock_outline, '密码', '••••••••', masked: detail.password),
                    if (detail.url.isNotEmpty)
                      _row(Icons.link, '网址', detail.url),
                    if (detail.notes.isNotEmpty)
                      _row(Icons.notes, '备注', detail.notes),
                    ...detail.customFields
                        .map((f) => _row(Icons.label_outline, f.key, f.value)),
                  ],
                ),
              ),
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
      onCopy: onCopy,
    );
  }
}
