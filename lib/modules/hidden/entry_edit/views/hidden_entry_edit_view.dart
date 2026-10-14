import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/entry_form_widgets.dart';
import '../controllers/hidden_entry_edit_controller.dart';

class HiddenEntryEditView extends GetView<HiddenEntryEditController> {
  const HiddenEntryEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? '编辑隐藏密码' : '新建隐藏密码')),
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
