import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ---- 安全 ----
          _sectionHeader('安全'),
          ListTile(
            leading: const Icon(Icons.lock_clock_outlined),
            title: const Text('自动锁定'),
            subtitle: Obx(() => Text('${controller.autoLockMinutes.value} 分钟')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAutoLockDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('生物识别解锁'),
            subtitle: Obx(() => Text(controller.canUseBiometric.value
                ? (controller.isBiometricEnabled.value ? '已开启' : '已关闭')
                : '设备不支持')),
            trailing: Obx(() => Switch(
                  value: controller.isBiometricEnabled.value,
                  onChanged: controller.canUseBiometric.value
                      ? controller.toggleBiometric
                      : null,
                )),
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('定期主密码验证'),
            subtitle: Obx(() => Text('${controller.masterCheckDays.value} 天')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMasterCheckDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('修改主密码'),
            onTap: controller.showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.screenshot),
            title: const Text('禁止截屏'),
            subtitle: const Text('阻止系统截屏和录屏'),
            trailing: Obx(() => Switch(
                  value: controller.isSecureScreen.value,
                  onChanged: controller.toggleSecureScreen,
                )),
          ),
          const Divider(),

          // ---- 数据管理 ----
          _sectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.gotoCategoryManage,
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('导出备份'),
            subtitle: const Text('加密 JSON 格式'),
            onTap: controller.showExportDialog,
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导入备份'),
            onTap: controller.showImportDialog,
          ),
          const Divider(),

          // ---- 关于 ----
          _sectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: Obx(() => Text(controller.appVersion.value)),
          ),
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('数据存储'),
            subtitle: Text('纯本地存储，无网络通信'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  void _showAutoLockDialog() {
    final options = [1, 5, 15, 30, 60];
    Get.defaultDialog(
      title: '自动锁定',
      backgroundColor: Colors.white,
      content: Column(
        children: options
            .map((m) => ListTile(
                  title: Text('$m 分钟'),
                  trailing: Obx(() => controller.autoLockMinutes.value == m
                      ? Icon(Icons.check, color: Theme.of(Get.context!).colorScheme.primary)
                      : const SizedBox.shrink()),
                  onTap: () {
                    controller.setAutoLockMinutes(m);
                    Get.back();
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showMasterCheckDialog() {
    final options = [7, 14, 30, 60, 90];
    Get.defaultDialog(
      title: '定期验证周期',
      backgroundColor: Colors.white,
      content: Column(
        children: options
            .map((d) => ListTile(
                  title: Text('$d 天'),
                  trailing: Obx(() => controller.masterCheckDays.value == d
                      ? Icon(Icons.check, color: Theme.of(Get.context!).colorScheme.primary)
                      : const SizedBox.shrink()),
                  onTap: () {
                    controller.setMasterCheckDays(d);
                    Get.back();
                  },
                ))
            .toList(),
      ),
    );
  }
}
