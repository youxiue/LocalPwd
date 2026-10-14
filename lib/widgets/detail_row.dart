import 'package:flutter/material.dart';

import '../core/utils/app_notification.dart';

/// 密码详情弹窗中的信息行
///
/// [secretValue] 非空时表示密码字段：
/// 默认以圆点掩码显示，可通过左侧的显示/隐藏按钮切换查看明文。
/// 复制按钮始终复制真实值。
class DetailRow extends StatefulWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.secretValue,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;

  /// 密码字段的真实值；非空时启用显示/隐藏切换
  final String? secretValue;

  /// 复制回调，参数为需要复制的文本
  final ValueChanged<String> onCopy;

  @override
  State<DetailRow> createState() => _DetailRowState();
}

class _DetailRowState extends State<DetailRow> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final isSecret = widget.secretValue != null;
    final displayValue = isSecret
        ? (_visible ? widget.secretValue! : '••••••••')
        : widget.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(widget.icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(displayValue, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
          if (isSecret)
            IconButton(
              icon: Icon(
                _visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              tooltip: _visible ? '隐藏密码' : '显示密码',
              onPressed: () => setState(() => _visible = !_visible),
            ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: '复制',
            onPressed: () {
              widget.onCopy(widget.secretValue ?? widget.value);
              AppNotification.info('已复制', '将在 30 秒后自动清除');
            },
          ),
        ],
      ),
    );
  }
}
