import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../widgets/backup_dialogs.dart';
import '../../controllers/hidden_controller.dart';

class HiddenSettingsController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _auth = AuthService.instance;
  final _export = ExportService.instance;

  final isBusy = false.obs;

  void gotoCategoryManage() {
    Get.toNamed(AppRoutes.hiddenCategoryManage);
  }

  void showConfigDialog() {
    final triggerCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final error = ''.obs;

    Get.defaultDialog(
      title: '修改隐藏模式配置',
      backgroundColor: Colors.white,
      barrierDismissible: false,
      content: Column(
        children: [
          TextField(
            controller: triggerCtrl,
            decoration: const InputDecoration(
              labelText: '触发字符串',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '新密码',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
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
              ? Text(error.value, style: const TextStyle(color: Colors.red, fontSize: 12))
              : const SizedBox.shrink()),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('取消')),
        Obx(() => FilledButton(
              onPressed: isBusy.value
                  ? null
                  : () async {
                      if (isBusy.value) return;
                      final trigger = triggerCtrl.text.trim();
                      final pwd = pwdCtrl.text.trim();
                      final confirm = confirmCtrl.text.trim();

                      if (trigger.isEmpty || pwd.isEmpty) {
                        error.value = '不能为空';
                        return;
                      }
                      if (pwd.length < 6) {
                        error.value = '密码至少 6 位';
                        return;
                      }
                      if (pwd != confirm) {
                        error.value = '两次密码不一致';
                        return;
                      }

                      isBusy.value = true;
                      try {
                        await _auth.setupHiddenMode(trigger, pwd);
                        Get.back();
                        AppNotification.success('成功', '隐藏模式配置已更新');
                      } catch (e) {
                        AppNotification.error('错误', '保存失败');
                      } finally {
                        isBusy.value = false;
                      }
                    },
              child: const Text('保存'),
            )),
      ],
    );
  }

  void showExportDialog() {
    showBackupExportDialog(
      title: '导出隐藏备份',
      description: '设置导出密码，导入时需要输入相同密码',
      onSubmit: _doExport,
    );
  }

  Future<void> _doExport(String exportPassword) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final path = await _export.exportToFile(
        db: _db,
        sessionKey: _auth.hiddenSessionKey!,
        exportPassword: exportPassword,
        isHidden: true,
      );
      // 分享完成后删除临时备份文件，避免加密备份长期驻留本机
      await Share.shareXFiles([XFile(path)], text: '隐藏密码库备份');
      await _export.deleteExportFile(path);
    } catch (e) {
      AppNotification.error('导出失败', e.toString());
    } finally {
      isBusy.value = false;
    }
  }

  void showImportDialog() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      _showImportPasswordDialog(result.files.single.path!);
    } catch (e) {
      AppNotification.error('错误', '无法选择文件');
    }
  }

  void _showImportPasswordDialog(String filePath) {
    showBackupImportDialog(
      title: '导入隐藏备份',
      description: '输入导出时设置的密码',
      onSubmit: (password) => _doImport(filePath, password),
    );
  }

  Future<void> _doImport(String filePath, String importPassword) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await _export.importFromFile(
        filePath: filePath,
        db: _db,
        sessionKey: _auth.hiddenSessionKey!,
        importPassword: importPassword,
        isHidden: true,
      );

      if (Get.isRegistered<HiddenController>()) {
        Get.find<HiddenController>().loadData();
      }

      AppNotification.success('导入成功', '数据已恢复');
    } catch (e) {
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '文件格式错误或密码不匹配';
      AppNotification.error('导入失败', msg);
    } finally {
      isBusy.value = false;
    }
  }
}
