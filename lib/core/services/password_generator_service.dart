import 'dart:math';

/// 密码生成器服务
class PasswordGeneratorService {
  PasswordGeneratorService._();
  static final PasswordGeneratorService instance = PasswordGeneratorService._();

  static const _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _numbers = '0123456789';
  static const _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  String generate({
    int length = 16,
    bool useLowercase = true,
    bool useUppercase = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    final buffer = StringBuffer();
    final charPool = StringBuffer();

    if (useLowercase) charPool.write(_lowercase);
    if (useUppercase) charPool.write(_uppercase);
    if (useNumbers) charPool.write(_numbers);
    if (useSymbols) charPool.write(_symbols);

    if (charPool.isEmpty) return '';

    final chars = charPool.toString();
    final random = Random.secure();

    for (var i = 0; i < length; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }

  /// 计算密码强度（0-4）
  int strength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 16) score++;
    if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password) && RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }
}
