import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// 禁止截屏服务：通过 MethodChannel 设置 Android FLAG_SECURE
class SecureWindowService {
  SecureWindowService._();
  static final SecureWindowService instance = SecureWindowService._();

  static const _channel = MethodChannel('com.localpwd.local_pwd/secure');
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> isEnabled() async {
    final v = await _storage.read(key: AppConstants.keySecureScreen);
    return v == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: AppConstants.keySecureScreen, value: enabled.toString());
    await apply();
  }

  /// 应用当前设置（App 启动时调用）
  Future<void> apply() async {
    final enabled = await isEnabled();
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': enabled});
    } catch (_) {
      // 非 Android 平台或 channel 未注册
    }
  }
}
