import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 统一消息通知
class AppNotification {
  AppNotification._();

  /// 主题主色（与全站强调色一致）
  static const _primary = Color(0xFF37BC6E);
  static const _primaryDark = Color(0xFF1E7A44);

  static void success(String title, String message) {
    _show(title, message, isError: false);
  }

  static void error(String title, String message) {
    _show(title, message, isError: true);
  }

  static void info(String title, String message) {
    _show(title, message, isError: false, isInfo: true);
  }

  static void _show(String title, String message,
      {bool isError = false, bool isInfo = false}) {
    Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      // 成功/提示走主题主色，错误保留语义红色
      backgroundColor: isError
          ? Colors.red.shade50
          : isInfo
              ? const Color(0x1437BC6E)
              : const Color(0x1F37BC6E),
      colorText: isError
          ? Colors.red.shade800
          : isInfo
              ? _primary
              : _primaryDark,
      icon: Icon(
        isError ? Icons.error_outline : (isInfo ? Icons.info_outline : Icons.check_circle_outline),
        color: isError ? Colors.red.shade600 : _primary,
      ),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }
}
