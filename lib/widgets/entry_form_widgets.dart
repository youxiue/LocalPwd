import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/routes.dart';
import '../core/models/decrypted_entry.dart';
import '../modules/entry_edit/controllers/entry_edit_controller.dart';

/// 新增/编辑条目表单主体，普通模式与隐藏模式共用。
///
/// 直接读取 [EntryEditControllerBase] 的响应式字段，视觉与交互保持一致。
class EntryFormBody extends StatelessWidget {
  final EntryEditControllerBase controller;

  const EntryFormBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final id = controller.selectedCategoryId.value;
            final catName = id == null
                ? '无分类'
                : controller.categories
                        .where((c) => c.id == id)
                        .map((c) => c.name)
                        .firstOrNull ??
                    '无分类';
            return PopupMenuButton<String>(
              offset: const Offset(0, 56),
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32,
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '分类',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_outlined, size: 20),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(catName, style: const TextStyle(fontSize: 16)),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(value: '', child: Text('无分类')),
                ...controller.categories.map(
                    (c) => PopupMenuItem(value: c.id, child: Text(c.name))),
              ],
              onSelected: (v) =>
                  controller.selectCategory(v.isEmpty ? null : v),
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: controller.usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => TextField(
                controller: controller.passwordController,
                obscureText: controller.isObscure.value,
                decoration: InputDecoration(
                  labelText: '密码',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(controller.isObscure.value
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: controller.toggleObscure,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => Get.toNamed(AppRoutes.generator)
                            ?.then((val) {
                          if (val != null && val is String) {
                            controller.passwordController.text = val;
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              )),
          // 密码安全等级
          Obx(() {
            final level = controller.passwordStrength.value;
            if (level < 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: EntryStrengthIndicator(level: level),
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: controller.urlController,
            decoration: const InputDecoration(
              labelText: '网址',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link, size: 20),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.notesController,
            decoration: const InputDecoration(
              labelText: '备注',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes, size: 20),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('自定义字段', style: Theme.of(context).textTheme.titleSmall),
              TextButton.icon(
                onPressed: controller.addCustomField,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.customFields.length,
                itemBuilder: (ctx, i) => EntryCustomFieldRow(
                  key: ValueKey(i),
                  field: controller.customFields[i],
                  onRemove: () => controller.removeCustomField(i),
                ),
              )),
        ],
      ),
    );
  }
}

/// 自定义字段行 — 独立管理 TextEditingController 避免 rebuild 丢焦点
class EntryCustomFieldRow extends StatefulWidget {
  final CustomField field;
  final VoidCallback onRemove;

  const EntryCustomFieldRow({
    super.key,
    required this.field,
    required this.onRemove,
  });

  @override
  State<EntryCustomFieldRow> createState() => _EntryCustomFieldRowState();
}

class _EntryCustomFieldRowState extends State<EntryCustomFieldRow> {
  late TextEditingController _keyCtrl;
  late TextEditingController _valueCtrl;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.field.key);
    _valueCtrl = TextEditingController(text: widget.field.value);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                hintText: '名称',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => widget.field.key = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _valueCtrl,
              decoration: const InputDecoration(
                hintText: '值',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => widget.field.value = v,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

/// 密码强度指示器：横条形式，宽度与输入框一致
class EntryStrengthIndicator extends StatelessWidget {
  final int level;

  const EntryStrengthIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    const labels = ['很弱', '弱', '中等', '强', '很强'];
    const colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.lightGreen,
      Colors.green,
    ];
    final color = colors[level];

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 横条：5段占满宽度
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Row(
                children: List.generate(
                  5,
                  (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 4 ? 2 : 0),
                      color: i <= level ? color : Colors.grey.shade200,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(labels[level], style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
