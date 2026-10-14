import 'dart:async';

import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

/// 剪贴板服务：复制后自动清除
class ClipboardService {
  ClipboardService._();
  static final ClipboardService instance = ClipboardService._();

  Timer? _clearTimer;

  /// 复制文本到剪贴板，N 秒后自动清除
  Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _clearTimer?.cancel();
    _clearTimer = Timer(
      const Duration(seconds: AppConstants.clipboardClearSeconds),
      _clearClipboard,
    );
  }

  void _clearClipboard() async {
    // 用空字符串覆盖剪贴板
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// 立即清空剪贴板并取消定时器（锁定/退后台时调用，避免明文残留）
  void clear() {
    _clearTimer?.cancel();
    _clearTimer = null;
    _clearClipboard();
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}
