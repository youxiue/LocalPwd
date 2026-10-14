import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/routes.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/secure_window_service.dart';
import '../../../core/storage/database.dart';
import '../../../core/utils/app_notification.dart';
import '../../../widgets/backup_dialogs.dart';
import '../../home/controllers/home_controller.dart';

class SettingsController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _auth = AuthService.instance;
  final _crypto = CryptoService.instance;
  final _export = ExportService.instance;

  final autoLockMinutes = 1.obs;
  final masterCheckDays = 30.obs;
  final isBiometricEnabled = false.obs;
  final canUseBiometric = false.obs;
  final isSecureScreen = false.obs;
  final appVersion = ''.obs;
  final isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    autoLockMinutes.value = await _auth.getAutoLockMinutes();
    masterCheckDays.value = await _auth.getMasterCheckDays();
    isBiometricEnabled.value = await _auth.isBiometricEnabled;
    canUseBiometric.value = await _auth.canCheckBiometrics;
    isSecureScreen.value = await SecureWindowService.instance.isEnabled();
    final info = await PackageInfo.fromPlatform();
    appVersion.value = info.version;
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    await _auth.setAutoLockMinutes(minutes);
    autoLockMinutes.value = minutes;
  }

  Future<void> setMasterCheckDays(int days) async {
    await _auth.setMasterCheckDays(days);
    masterCheckDays.value = days;
  }

  Future<void> toggleBiometric(bool enabled) async {
    // 先验证指纹
    final ok = await _auth.authenticateBiometric();
    if (!ok) {
      AppNotification.error('验证失败', '请重试');
      return;
    }
    await _auth.setBiometricEnabled(enabled);
    isBiometricEnabled.value = enabled;
    AppNotification.success('成功', enabled ? '生物识别已开启' : '生物识别已关闭');
  }

  Future<void> toggleSecureScreen(bool enabled) async {
    await SecureWindowService.instance.setEnabled(enabled);
    isSecureScreen.value = enabled;
  }

  void showExportDialog() {
    showBackupExportDialog(
      title: '导出备份',
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
        sessionKey: _auth.sessionKey!,
        exportPassword: exportPassword,
        isHidden: false,
      );
      // 分享完成后删除临时备份文件，避免加密备份长期驻留本机
      await Share.shareXFiles([XFile(path)], text: '密码库备份');
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
      title: '导入备份',
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
        sessionKey: _auth.sessionKey!,
        importPassword: importPassword,
        isHidden: false,
      );

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadData();
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

  void showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final error = ''.obs;

    Get.defaultDialog(
      title: '修改主密码',
      backgroundColor: Colors.white,
      content: Column(
        children: [
          TextField(
            controller: oldCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '当前密码',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtrl,
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
                  : () => _doChangePassword(oldCtrl, newCtrl, confirmCtrl, error),
              child: const Text('修改'),
            )),
      ],
    );
  }

  Future<void> _doChangePassword(
    TextEditingController oldCtrl,
    TextEditingController newCtrl,
    TextEditingController confirmCtrl,
    RxString error,
  ) async {
    if (isBusy.value) return;

    final oldPwd = oldCtrl.text.trim();
    final newPwd = newCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty) {
      error.value = '不能为空';
      return;
    }
    if (newPwd.length < 6) {
      error.value = '新密码至少 6 位';
      return;
    }
    if (newPwd != confirm) {
      error.value = '两次密码不一致';
      return;
    }

    isBusy.value = true;
    try {
      // 验证旧密码
      final salt = await _auth.getStoredSalt();
      final verifyHash = await _auth.getMasterVerify();
      if (salt == null || verifyHash == null) {
        error.value = '配置错误';
        return;
      }

      final oldKey = await _crypto.deriveKey(oldPwd, salt);
      if (!await _crypto.verifyKey(oldKey, verifyHash)) {
        error.value = '当前密码错误';
        return;
      }

      // 用新 KEK 重新加密 DEK（DEK 本身不变，条目数据无需重加密）
      final newSalt = await _crypto.generateSalt();
      final newKek = await _crypto.deriveKey(newPwd, newSalt);
      final newVerify = await _crypto.generateVerifyHash(newKek);

      await _auth.saveMasterPasswordConfig(newSalt, newVerify, oldKey, newKek);

      Get.back();
      AppNotification.success('成功', '主密码已修改');
    } catch (e) {
      AppNotification.error('错误', '修改失败，数据未变更');
    } finally {
      isBusy.value = false;
    }
  }

  void gotoCategoryManage() {
    Get.toNamed(AppRoutes.categoryManage);
  }
}
