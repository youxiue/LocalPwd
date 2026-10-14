import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/generator_controller.dart';

class GeneratorView extends GetView<GeneratorController> {
  const GeneratorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('密码生成器'),
        actions: [
          TextButton(
            onPressed: controller.usePassword,
            child: const Text('使用'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 生成结果
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(() => SelectableText(
                    controller.generatedPassword.value.isEmpty
                        ? '点击下方按钮生成'
                        : controller.generatedPassword.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  )),
            ),
            const SizedBox(height: 12),
            // 强度指示
            Obx(() => _buildStrengthBar(controller.strength.value)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.copy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('复制'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.generate,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重新生成'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 长度滑块
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('长度'),
                        Text('${controller.length.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: controller.length.value.toDouble(),
                      min: 8,
                      max: 32,
                      divisions: 24,
                      onChanged: (v) {
                        controller.length.value = v.toInt();
                        controller.generate();
                      },
                    ),
                  ],
                )),
            const SizedBox(height: 8),
            // 选项
            _buildOption('小写字母 (a-z)', controller.useLowercase),
            _buildOption('大写字母 (A-Z)', controller.useUppercase),
            _buildOption('数字 (0-9)', controller.useNumbers),
            _buildOption('特殊符号 (!@#...)', controller.useSymbols),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthBar(int level) {
    const labels = ['很弱', '弱', '中等', '强', '很强'];
    const colors = [Colors.red, Colors.orange, Colors.amber, Colors.lightGreen, Colors.green];
    final color = colors[level];
    return Row(
      children: [
        const Text('强度：', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: (level + 1) / 5,
            color: color,
            backgroundColor: Colors.grey.shade300,
            minHeight: 6,
          ),
        ),
        const SizedBox(width: 8),
        Text(labels[level], style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOption(String label, RxBool rxVal) {
    return Obx(() => SwitchListTile(
          title: Text(label, style: const TextStyle(fontSize: 14)),
          value: rxVal.value,
          dense: true,
          onChanged: (v) {
            final allOptions = [
              controller.useLowercase,
              controller.useUppercase,
              controller.useNumbers,
              controller.useSymbols,
            ];
            final enabledCount = allOptions.where((e) => e.value).length;
            // 禁用时至少保留一个选项
            if (!v && enabledCount <= 1) return;
            rxVal.value = v;
            controller.generate();
          },
        ));
  }
}
