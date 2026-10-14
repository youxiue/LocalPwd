import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../app/routes.dart';

class UnlockController extends GetxController {
  final _auth = AuthService.instance;

  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final isInitialized = false.obs;
  final needsMasterCheck = false.obs;
  final canUseBiometric = false.obs;
  final isBiometricEnabled = false.obs;
  final isObscure = true.obs;
  final errorMessage = ''.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initState();
  }

  Future<void> _initState() async {
    isInitialized.value = await _auth.isInitialized;
    needsMasterCheck.value = await _auth.needMasterPasswordCheck;
    canUseBiometric.value = await _auth.canCheckBiometrics;
    isBiometricEnabled.value = await _auth.isBiometricEnabled;

    // 如果生物识别可用且不需要定期验证，尝试自动弹出生物识别
    if (isInitialized.value &&
        !needsMasterCheck.value &&
        isBiometricEnabled.value &&
        canUseBiometric.value) {
      await tryBiometric();
      // 生物识别成功已导航到首页，controller 已 dispose，不再更新 UI
      if (isClosed) return;
    }

    isLoading.value = false;
  }

  /// 首次设置主密码
  Future<void> setupMasterPassword() async {
    final pw = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (pw.isEmpty) {
      errorMessage.value = '请输入主密码';
      return;
    }
    if (pw.length < 6) {
      errorMessage.value = '密码至少 6 位';
      return;
    }
    if (pw != confirm) {
      errorMessage.value = '两次密码不一致';
      return;
    }

    errorMessage.value = '';
    isLoading.value = true;

    await _auth.setupMasterPassword(pw);
    isLoading.value = false;
    Get.offAllNamed(AppRoutes.home);
  }

  /// 验证主密码
  Future<void> unlock() async {
    final pw = passwordController.text.trim();
    if (pw.isEmpty) {
      errorMessage.value = '请输入主密码';
      return;
    }

    errorMessage.value = '';
    isLoading.value = true;

    final ok = await _auth.verifyMasterPassword(pw);

    if (ok) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      isLoading.value = false;
      errorMessage.value = '密码错误';
    }
  }

  /// 生物识别解锁
  Future<void> tryBiometric() async {
    final ok = await _auth.tryBiometricUnlock();
    if (ok) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void toggleObscure() => isObscure.value = !isObscure.value;

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
