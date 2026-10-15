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
            decoration: InputDecoration(
              labelText: '标题',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title, size: 20),
              suffixIcon: FieldClearButton(controller: controller.titleController),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final selectedIds = controller.selectedCategoryIds;
            final names = controller.categories
                .where((c) => selectedIds.contains(c.id))
                .map((c) => c.name)
                .toList();
            return InkWell(
              onTap: () => _showCategoryPickerSheet(context, controller),
              child: InputDecorator(
                // 内容为空时让 label 落回输入框内，与其它输入框保持一致
                isEmpty: names.isEmpty,
                decoration: InputDecoration(
                  labelText: '分类',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category_outlined, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (names.isNotEmpty)
                        IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.cancel,
                              size: 18, color: Colors.grey),
                          tooltip: '清空',
                          onPressed: () =>
                              controller.setCategories(const []),
                        ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                child: Text(
                  names.join(', '),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: controller.usernameController,
            decoration: InputDecoration(
              labelText: '用户名',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              suffixIcon: FieldClearButton(controller: controller.usernameController),
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
                      FieldClearButton(controller: controller.passwordController),
                      IconButton(
                        icon: Icon(controller.isObscure.value
                            ? Icons.visibility_off
                            : Icons.visibility, size: 20),
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
            decoration: InputDecoration(
              labelText: '网址',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link, size: 20),
              suffixIcon: FieldClearButton(controller: controller.urlController),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.notesController,
            decoration: InputDecoration(
              labelText: '备注',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.notes, size: 20),
              suffixIcon: FieldClearButton(controller: controller.notesController),
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
              decoration: InputDecoration(
                hintText: '名称',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: FieldClearButton(controller: _keyCtrl),
              ),
              onChanged: (v) => widget.field.key = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _valueCtrl,
              decoration: InputDecoration(
                hintText: '值',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: FieldClearButton(controller: _valueCtrl),
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

/// 输入框清除按钮：内容为空时自动隐藏
class FieldClearButton extends StatelessWidget {
  final TextEditingController controller;

  const FieldClearButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return IconButton(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
          tooltip: '清空',
          onPressed: controller.clear,
        );
      },
    );
  }
}

/// 分类多选底部弹窗：标签式排列，默认灰色、选中为主题色。
/// 高度固定，标签过多时内容区可上下滚动；不选即视为无分类。
void _showCategoryPickerSheet(
    BuildContext context, EntryEditControllerBase controller) {
  final tempSelected = controller.selectedCategoryIds.toSet();
  final primary = Theme.of(context).colorScheme.primary;
  final sheetHeight = MediaQuery.sizeOf(context).height * 0.5;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setState) {
        final categories = controller.categories;
        return SafeArea(
          child: SizedBox(
            height: sheetHeight,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '选择分类',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: categories.isEmpty
                      ? Center(
                          child: Text(
                            '暂无分类',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: categories
                                .map((c) => _CategoryTag(
                                      label: c.name,
                                      selected: tempSelected.contains(c.id),
                                      color: primary,
                                      onTap: () => setState(() {
                                        if (!tempSelected.remove(c.id)) {
                                          tempSelected.add(c.id);
                                        }
                                      }),
                                    ))
                                .toList(),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        controller.setCategories(tempSelected.toList());
                        Navigator.of(sheetCtx).pop();
                      },
                      child: const Text('确定'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// 分类标签：默认灰底灰字，选中为主题色底白字
class _CategoryTag extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTag({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
