import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/unlock_controller.dart';

class UnlockView extends GetView<UnlockController> {
  const UnlockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return controller.isInitialized.value
              ? _buildUnlockUI()
              : _buildSetupUI();
        }),
      ),
    );
  }

  /// 首次设置
  Widget _buildSetupUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/app_icon.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text('设置主密码', style: Get.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '主密码用于加密所有数据，忘记后无法找回',
              style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Obx(() => TextField(
              controller: controller.passwordController,
              obscureText: controller.isObscure.value,
              decoration: InputDecoration(
                labelText: '主密码',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(controller.isObscure.value
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: controller.toggleObscure,
                ),
              ),
            )),
            const SizedBox(height: 16),
            Obx(() => TextField(
              controller: controller.confirmController,
              obscureText: controller.isObscure.value,
              decoration: InputDecoration(
                labelText: '确认密码',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(controller.isObscure.value
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: controller.toggleObscure,
                ),
              ),
            )),
            const SizedBox(height: 8),
            Obx(() => controller.errorMessage.value.isNotEmpty
                ? Text(controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red))
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.setupMasterPassword,
                child: const Text('创建密码库'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 解锁界面
  Widget _buildUnlockUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/app_icon.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text('解锁', style: Get.textTheme.headlineSmall),
            const SizedBox(height: 32),
            Obx(() => TextField(
              controller: controller.passwordController,
              obscureText: controller.isObscure.value,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '主密码',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(controller.isObscure.value
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: controller.toggleObscure,
                ),
              ),
              onSubmitted: (_) => controller.unlock(),
            )),
            const SizedBox(height: 8),
            Obx(() => controller.errorMessage.value.isNotEmpty
                ? Text(controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red))
                : const SizedBox.shrink()),
            if (controller.needsMasterCheck.value)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '已超过定期验证周期，请输入主密码',
                  style: Get.textTheme.bodySmall?.copyWith(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.unlock,
                child: const Text('解锁'),
              ),
            ),
            if (controller.canUseBiometric.value &&
                controller.isBiometricEnabled.value &&
                !controller.needsMasterCheck.value)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  onPressed: controller.tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('使用生物识别'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
