import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/hidden_settings_controller.dart';

class HiddenSettingsView extends GetView<HiddenSettingsController> {
  const HiddenSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐藏模式设置')),
      body: ListView(
        children: [
          _sectionHeader('安全'),
          ListTile(
            leading: const Icon(Icons.visibility_off),
            title: const Text('修改触发字符串和密码'),
            subtitle: const Text('修改隐藏模式入口配置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.showConfigDialog,
          ),
          const Divider(),
          _sectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.gotoCategoryManage,
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('导出隐藏备份'),
            subtitle: const Text('加密 JSON 格式'),
            onTap: controller.showExportDialog,
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导入隐藏备份'),
            onTap: controller.showImportDialog,
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
}
