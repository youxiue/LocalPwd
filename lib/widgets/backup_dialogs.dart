import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 导出备份密码输入弹窗（普通模式 / 隐藏模式共用）
///
/// [title] 弹窗标题；[description] 说明文案；
/// [onSubmit] 校验通过并关闭弹窗后执行的回调，参数为用户输入的导出密码。
void showBackupExportDialog({
  required String title,
  required String description,
  required Future<void> Function(String password) onSubmit,
}) {
  final pwdCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final error = ''.obs;

  unawaited(Get.defaultDialog(
    title: title,
    backgroundColor: Colors.white,
    content: Column(
      children: [
        Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(
          controller: pwdCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '导出密码',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: confirmCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '确认密码',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => error.value.isNotEmpty
            ? Text(error.value,
                style: const TextStyle(color: Colors.red, fontSize: 12))
            : const SizedBox.shrink()),
      ],
    ),
    actions: [
      TextButton(onPressed: Get.back, child: const Text('取消')),
      FilledButton(
        onPressed: () async {
          final pwd = pwdCtrl.text.trim();
          final confirm = confirmCtrl.text.trim();
          if (pwd.length < 6) {
            error.value = '密码至少 6 位';
            return;
          }
          if (pwd != confirm) {
            error.value = '两次密码不一致';
            return;
          }
          Get.back();
          await onSubmit(pwd);
        },
        child: const Text('导出'),
      ),
    ],
  ));
}

/// 导入备份密码输入弹窗（普通模式 / 隐藏模式共用）
///
/// [title] 弹窗标题；[description] 说明文案；
/// [onSubmit] 校验通过并关闭弹窗后执行的回调，参数为用户输入的导入密码。
void showBackupImportDialog({
  required String title,
  required String description,
  required Future<void> Function(String password) onSubmit,
}) {
  final pwdCtrl = TextEditingController();
  final error = ''.obs;

  unawaited(Get.defaultDialog(
    title: title,
    backgroundColor: Colors.white,
    content: Column(
      children: [
        Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(
          controller: pwdCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '导入密码',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => error.value.isNotEmpty
            ? Text(error.value,
                style: const TextStyle(color: Colors.red, fontSize: 12))
            : const SizedBox.shrink()),
      ],
    ),
    actions: [
      TextButton(onPressed: Get.back, child: const Text('取消')),
      FilledButton(
        onPressed: () async {
          final pwd = pwdCtrl.text.trim();
          if (pwd.isEmpty) {
            error.value = '请输入密码';
            return;
          }
          Get.back();
          await onSubmit(pwd);
        },
        child: const Text('导入'),
      ),
    ],
  ));
}
