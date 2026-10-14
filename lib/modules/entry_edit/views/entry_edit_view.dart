import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/entry_form_widgets.dart';
import '../controllers/entry_edit_controller.dart';

class EntryEditView extends GetView<EntryEditController> {
  const EntryEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? '编辑密码' : '新建密码')),
        actions: [
          TextButton(
            onPressed: controller.save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: EntryFormBody(controller: controller),
    );
  }
}
