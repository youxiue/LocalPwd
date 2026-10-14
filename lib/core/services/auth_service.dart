import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../constants/app_constants.dart';
import '../crypto/crypto_service.dart';

/// 认证服务：主密码、生物识别、隐藏模式、定期验证
///
/// 密钥层级架构：
///   Password → Argon2id → KEK（密钥加密密钥）
///   KEK → 加密 DEK（数据加密密钥，随机256位，加密后存 SecureStorage）
///   DEK → 加密所有条目数据 + SQLCipher 数据库密钥
///
/// 改密码只需用新 KEK 重新加密 DEK（32字节），无需重加密全部条目。
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _localAuth = LocalAuthentication();
  final _crypto = CryptoService.instance;

  // 内存中的密钥，锁定时为 null
  // KEK 不存内存：改密码时由控制器传入 oldKek 参数，正常使用只需 DEK
  SecretKey? _dek; // 数据加密密钥（随机生成，不随密码变更）
  SecretKey? _hiddenKek; // 隐藏模式 KEK（setupHiddenMode 时解密旧 DEK 需要）
  SecretKey? _hiddenDek; // 隐藏模式 DEK
  bool _isHiddenMode = false;
  bool _hiddenNeedsSetup = false;

  /// 当前数据加密密钥（供控制器加密/解密条目数据，控制器层零改动）
  SecretKey? get sessionKey => _dek;
  SecretKey? get hiddenSessionKey => _hiddenDek;
  bool get isHiddenMode => _isHiddenMode;
  bool get hiddenNeedsSetup => _hiddenNeedsSetup;
  bool get isLocked => _dek == null;

  // ---- 初始化检查 ----

  /// 是否已设置主密码
  Future<bool> get isInitialized async {
    final salt = await _secureStorage.read(key: AppConstants.keyMasterSalt);
    final verify = await _secureStorage.read(key: AppConstants.keyMasterVerify);
    return salt != null && verify != null;
  }

  // ---- 主密码 ----

  /// 首次设置主密码
  Future<void> setupMasterPassword(String password) async {
    final salt = await _crypto.generateSalt();
    final kek = await _crypto.deriveKey(password, salt);
    final verifyHash = await _crypto.generateVerifyHash(kek);

    // 生成随机 DEK，用 KEK 加密后存储
    final dek = await _crypto.generateDek();
    final encryptedDek = await _crypto.encryptKey(dek, kek);

    await _secureStorage.write(key: AppConstants.keyMasterSalt, value: base64Encode(salt));
    await _secureStorage.write(key: AppConstants.keyMasterVerify, value: verifyHash);
    await _secureStorage.write(key: AppConstants.keyEncryptedDek, value: encryptedDek);

    // 仅在开启生物识别时才持久化 DEK 字节，避免为绕过主密码留下后门
    if (await isBiometricEnabled) {
      final dekBytes = await _crypto.extractKeyBytes(dek);
      await _secureStorage.write(key: AppConstants.keySessionKey, value: base64Encode(dekBytes));
    }

    await _updateLastMasterInput();

    _dek = dek;
  }

  /// 验证主密码
  Future<bool> verifyMasterPassword(String password) async {
    final saltStr = await _secureStorage.read(key: AppConstants.keyMasterSalt);
    final verifyHash = await _secureStorage.read(key: AppConstants.keyMasterVerify);
    if (saltStr == null || verifyHash == null) return false;

    final salt = Uint8List.fromList(base64Decode(saltStr));
    final kek = await _crypto.deriveKey(password, salt);

    if (await _crypto.verifyKey(kek, verifyHash)) {
      // 解密 DEK
      final encryptedDek = await _secureStorage.read(key: AppConstants.keyEncryptedDek);
      if (encryptedDek == null) return false;
      final dek = await _crypto.decryptKey(encryptedDek, kek);

      _dek = dek;

      // 仅在开启生物识别时才更新 DEK 字节；未开启时确保不残留
      if (await isBiometricEnabled) {
        final dekBytes = await _crypto.extractKeyBytes(dek);
        await _secureStorage.write(key: AppConstants.keySessionKey, value: base64Encode(dekBytes));
      } else {
        await _secureStorage.delete(key: AppConstants.keySessionKey);
      }
      await _updateLastMasterInput();
      return true;
    }
    return false;
  }

  /// 获取已存储的盐
  Future<Uint8List?> getStoredSalt() async {
    final saltStr = await _secureStorage.read(key: AppConstants.keyMasterSalt);
    if (saltStr == null) return null;
    return Uint8List.fromList(base64Decode(saltStr));
  }

  /// 获取验证哈希
  Future<String?> getMasterVerify() async {
    return _secureStorage.read(key: AppConstants.keyMasterVerify);
  }

  /// 保存新主密码配置（修改主密码后调用）
  /// [oldKek] 旧 KEK，用于解密现有 DEK
  /// [newKek] 新 KEK，用于重加密 DEK（DEK 本身不变，条目数据无需重加密）
  Future<void> saveMasterPasswordConfig(
    Uint8List salt,
    String verifyHash,
    SecretKey oldKek,
    SecretKey newKek,
  ) async {
    // 读取现有加密 DEK
    final encryptedDek = await _secureStorage.read(key: AppConstants.keyEncryptedDek);
    if (encryptedDek == null) {
      throw StateError('Encrypted DEK not found');
    }

    // 用旧 KEK 解密 DEK，再用新 KEK 重加密
    final dek = await _crypto.decryptKey(encryptedDek, oldKek);
    final newEncryptedDek = await _crypto.encryptKey(dek, newKek);

    await _secureStorage.write(key: AppConstants.keyMasterSalt, value: base64Encode(salt));
    await _secureStorage.write(key: AppConstants.keyMasterVerify, value: verifyHash);
    await _secureStorage.write(key: AppConstants.keyEncryptedDek, value: newEncryptedDek);

    // 更新 DEK 字节供生物识别
    final isBioEnabled = await isBiometricEnabled;
    if (isBioEnabled) {
      final dekBytes = await _crypto.extractKeyBytes(dek);
      await _secureStorage.write(key: AppConstants.keySessionKey, value: base64Encode(dekBytes));
    }

    await _updateLastMasterInput();
    _dek = dek; // DEK 不变
  }

  // ---- 生物识别 ----

  Future<bool> get isBiometricEnabled async {
    final v = await _secureStorage.read(key: AppConstants.keyBiometricEnabled);
    return v == 'true';
  }

  Future<bool> get canCheckBiometrics async {
    return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
  }

  /// 仅验证生物识别身份（不检查是否已开启、不解锁）
  Future<bool> authenticateBiometric() async {
    if (!await canCheckBiometrics) return false;
    return await _localAuth.authenticate(
      localizedReason: '请验证身份',
      authMessages: const <AuthMessages>[
        AndroidAuthMessages(
          signInTitle: '验证身份',
          biometricHint: '',
          biometricNotRecognized: '无法识别，请重试',
          biometricSuccess: '验证成功',
          cancelButton: '取消',
          goToSettingsButton: '前往设置',
          goToSettingsDescription: '需要在设置中配置生物识别',
        ),
        IOSAuthMessages(
          cancelButton: '取消',
          goToSettingsButton: '前往设置',
          goToSettingsDescription: '需要在设置中配置生物识别',
          lockOut: '生物识别已被锁定，请前往设置解锁',
        ),
      ],
      options: const AuthenticationOptions(
        stickyAuth: false,
        biometricOnly: true,
      ),
    );
  }

  Future<bool> tryBiometricUnlock() async {
    if (!await isBiometricEnabled || !await canCheckBiometrics) return false;

    final didAuth = await _localAuth.authenticate(
      localizedReason: '请验证身份以解锁密码库',
      authMessages: const <AuthMessages>[
        AndroidAuthMessages(
          signInTitle: '解锁密码库',
          biometricHint: '',
          biometricNotRecognized: '无法识别，请重试',
          biometricSuccess: '验证成功',
          cancelButton: '取消',
          goToSettingsButton: '前往设置',
          goToSettingsDescription: '需要在设置中配置生物识别',
        ),
        IOSAuthMessages(
          cancelButton: '取消',
          goToSettingsButton: '前往设置',
          goToSettingsDescription: '需要在设置中配置生物识别',
          lockOut: '生物识别已被锁定，请前往设置解锁',
        ),
      ],
      options: const AuthenticationOptions(
        stickyAuth: false,
        biometricOnly: true,
      ),
    );
    if (!didAuth) return false;

    // 从 SecureStorage 读取 DEK 字节重建密钥
    final keyStr = await _secureStorage.read(key: AppConstants.keySessionKey);
    if (keyStr == null) return false;

    final dekBytes = Uint8List.fromList(base64Decode(keyStr));
    _dek = _crypto.fromBytes(dekBytes);
    // KEK 不设置：生物识别模式无法获得 KEK，改密码时需重新输入旧密码派生
    return true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: AppConstants.keyBiometricEnabled,
      value: enabled.toString(),
    );
    if (enabled) {
      // 存储 DEK 字节供生物识别解锁
      if (_dek != null) {
        final dekBytes = await _crypto.extractKeyBytes(_dek!);
        await _secureStorage.write(key: AppConstants.keySessionKey, value: base64Encode(dekBytes));
      }
    } else {
      await _secureStorage.delete(key: AppConstants.keySessionKey);
    }
  }

  // ---- 定期主密码验证 ----

  Future<bool> get needMasterPasswordCheck async {
    final lastStr = await _secureStorage.read(key: AppConstants.keyLastMasterInput);
    if (lastStr == null) return true;

    final last = DateTime.fromMillisecondsSinceEpoch(int.parse(lastStr));
    final daysStr = await _secureStorage.read(key: AppConstants.keyMasterCheckDays);
    final days = int.tryParse(daysStr ?? '') ?? AppConstants.defaultMasterCheckDays;

    return DateTime.now().difference(last).inDays >= days;
  }

  Future<int> getMasterCheckDays() async {
    final daysStr = await _secureStorage.read(key: AppConstants.keyMasterCheckDays);
    return int.tryParse(daysStr ?? '') ?? AppConstants.defaultMasterCheckDays;
  }

  Future<void> setMasterCheckDays(int days) async {
    await _secureStorage.write(key: AppConstants.keyMasterCheckDays, value: days.toString());
  }

  Future<void> _updateLastMasterInput() async {
    await _secureStorage.write(
      key: AppConstants.keyLastMasterInput,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  // ---- 自动锁定时长 ----

  Future<int> getAutoLockMinutes() async {
    final v = await _secureStorage.read(key: AppConstants.keyAutoLockMinutes);
    return int.tryParse(v ?? '') ?? AppConstants.defaultAutoLockMinutes;
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    await _secureStorage.write(key: AppConstants.keyAutoLockMinutes, value: minutes.toString());
  }

  // ---- 隐藏模式 ----

  /// 检查触发字符串
  Future<bool> checkTriggerString(String input) async {
    final trigger = await _secureStorage.read(key: AppConstants.keyTriggerString);
    return input == (trigger ?? AppConstants.defaultTriggerString);
  }

  /// 隐藏模式是否已配置
  Future<bool> get isHiddenConfigured async {
    final v = await _secureStorage.read(key: AppConstants.keyHiddenConfigured);
    return v == 'true';
  }

  /// 验证隐藏模式密码
  /// 首次进入用默认密码，之后需用户配置
  Future<bool> verifyHiddenPassword(String password) async {
    final configured = await isHiddenConfigured;

    if (!configured) {
      // 首次进入，使用默认密码
      if (password == AppConstants.defaultHiddenPassword) {
        // 复用已有盐（如果之前已进入过但未配置），避免旧数据无法解密
        final existingSaltStr = await _secureStorage.read(key: AppConstants.keyHiddenSalt);
        final salt = existingSaltStr != null
            ? Uint8List.fromList(base64Decode(existingSaltStr))
            : await _crypto.generateSalt();
        final kek = await _crypto.deriveKey(password, salt);
        final verifyHash = await _crypto.generateVerifyHash(kek);

        // 生成隐藏模式 DEK
        final dek = await _crypto.generateDek();
        final encryptedDek = await _crypto.encryptKey(dek, kek);

        await _secureStorage.write(key: AppConstants.keyHiddenSalt, value: base64Encode(salt));
        await _secureStorage.write(key: AppConstants.keyHiddenVerify, value: verifyHash);
        await _secureStorage.write(key: AppConstants.keyHiddenEncryptedDek, value: encryptedDek);

        _hiddenKek = kek;
        _hiddenDek = dek;
        _isHiddenMode = true;
        _hiddenNeedsSetup = true;
        return true;
      }
      return false;
    }

    // 已配置，正常验证
    final saltStr = await _secureStorage.read(key: AppConstants.keyHiddenSalt);
    final verifyHash = await _secureStorage.read(key: AppConstants.keyHiddenVerify);
    if (saltStr == null || verifyHash == null) return false;

    final salt = Uint8List.fromList(base64Decode(saltStr));
    final kek = await _crypto.deriveKey(password, salt);

    if (await _crypto.verifyKey(kek, verifyHash)) {
      // 解密隐藏模式 DEK
      final encryptedDek = await _secureStorage.read(key: AppConstants.keyHiddenEncryptedDek);
      if (encryptedDek == null) return false;
      final dek = await _crypto.decryptKey(encryptedDek, kek);

      _hiddenKek = kek;
      _hiddenDek = dek;
      _isHiddenMode = true;
      _hiddenNeedsSetup = false;
      return true;
    }
    return false;
  }

  /// 配置隐藏模式（修改触发字符串和密码）
  Future<void> setupHiddenMode(String newTriggerString, String newPassword) async {
    final salt = await _crypto.generateSalt();
    final newKek = await _crypto.deriveKey(newPassword, salt);
    final verifyHash = await _crypto.generateVerifyHash(newKek);

    // 读取现有加密 DEK，用旧 KEK 解密后用新 KEK 重加密
    final existingEncryptedDek = await _secureStorage.read(key: AppConstants.keyHiddenEncryptedDek);
    SecretKey dek;
    if (existingEncryptedDek != null && _hiddenKek != null) {
      dek = await _crypto.decryptKey(existingEncryptedDek, _hiddenKek!);
    } else {
      // 无现有 DEK（异常路径），生成新的
      dek = await _crypto.generateDek();
    }
    final newEncryptedDek = await _crypto.encryptKey(dek, newKek);

    await _secureStorage.write(key: AppConstants.keyHiddenSalt, value: base64Encode(salt));
    await _secureStorage.write(key: AppConstants.keyHiddenVerify, value: verifyHash);
    await _secureStorage.write(key: AppConstants.keyHiddenEncryptedDek, value: newEncryptedDek);
    await _secureStorage.write(key: AppConstants.keyTriggerString, value: newTriggerString);
    await _secureStorage.write(key: AppConstants.keyHiddenConfigured, value: 'true');

    _hiddenKek = newKek;
    _hiddenDek = dek;
    _isHiddenMode = true;
    _hiddenNeedsSetup = false;
  }

  /// 退出隐藏模式
  void exitHiddenMode() {
    _isHiddenMode = false;
    _hiddenKek = null;
    _hiddenDek = null;
  }

  // ---- 锁定 ----

  /// 锁定应用（清除内存中的所有密钥）
  void lock() {
    _dek = null;
    _hiddenKek = null;
    _hiddenDek = null;
    _isHiddenMode = false;
    _hiddenNeedsSetup = false;
  }
}
