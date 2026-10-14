/// 应用核心常量
class AppConstants {
  AppConstants._();

  // 安全存储 key
  static const String keyMasterSalt = 'master_salt';
  static const String keyMasterVerify = 'master_verify';
  static const String keyHiddenSalt = 'hidden_salt';
  static const String keyHiddenVerify = 'hidden_verify';
  static const String keyTriggerString = 'trigger_string';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyAutoLockMinutes = 'auto_lock_minutes';
  static const String keyMasterCheckDays = 'master_check_days';
  static const String keyLastMasterInput = 'last_master_input';
  static const String keyHiddenConfigured = 'hidden_configured';
  static const String keySessionKey = 'session_key';
  static const String keySecureScreen = 'secure_screen';
  // KEK+DEK 密钥层级：加密后的 DEK（用 KEK 加密）
  static const String keyEncryptedDek = 'encrypted_dek';
  static const String keyHiddenEncryptedDek = 'hidden_encrypted_dek';

  // 默认值
  static const String defaultTriggerString = '##secret';
  static const String defaultHiddenPassword = '000000';
  static const int defaultAutoLockMinutes = 1;
  static const int defaultMasterCheckDays = 30;
  static const int clipboardClearSeconds = 30;

  // 路由
  static const String routeUnlock = '/unlock';
  static const String routeHome = '/home';
  static const String routeEntryDetail = '/entry/:id';
  static const String routeEntryEdit = '/entry/edit';
  static const String routeCategoryManage = '/category';
  static const String routePasswordGenerator = '/generator';
  static const String routeSettings = '/settings';
  static const String routeHidden = '/hidden';
  static const String routeHiddenSettings = '/hidden/settings';
  static const String routeHiddenEntryEdit = '/hidden/entry/edit';
  static const String routeHiddenCategoryManage = '/hidden/category';

  // 加密参数
  static const int keyLength = 32; // 256-bit
  static const int nonceLength = 12; // GCM nonce
}
