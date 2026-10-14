import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../constants/app_constants.dart';

/// 加密服务：Argon2id 密钥派生 + AES-256-GCM 加解密
class CryptoService {
  CryptoService._();
  static final CryptoService instance = CryptoService._();

  final _argon2id = Argon2id(
    memory: 65536, // 64MB，OWASP 2025 推荐最低值
    iterations: 4, // 增加安全余量
    parallelism: 1,
    hashLength: AppConstants.keyLength,
  );
  final _aesGcm = AesGcm.with256bits();

  static const _macLength = 16; // GCM MAC

  /// 生成随机盐（16字节）
  Future<Uint8List> generateSalt() async {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// 生成随机 nonce（12字节）
  List<int> _generateNonce() {
    final random = Random.secure();
    return List<int>.generate(AppConstants.nonceLength, (_) => random.nextInt(256));
  }

  /// 生成随机 DEK（数据加密密钥，256位）
  Future<SecretKey> generateDek() async {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(AppConstants.keyLength, (_) => random.nextInt(256)),
    );
    return SecretKey(bytes);
  }

  /// 用 KEK 加密密钥（DEK），返回 base64
  /// 格式：base64(nonce + cipherText + mac)
  Future<String> encryptKey(SecretKey dataKey, SecretKey kek) async {
    final keyBytes = await extractKeyBytes(dataKey);
    final nonce = _generateNonce();
    final box = await _aesGcm.encrypt(
      keyBytes,
      secretKey: kek,
      nonce: nonce,
    );
    final combined = <int>[...box.nonce, ...box.cipherText, ...box.mac.bytes];
    return base64Encode(combined);
  }

  /// 用 KEK 解密密钥（DEK），返回 SecretKey
  Future<SecretKey> decryptKey(String encrypted, SecretKey kek) async {
    final combined = base64Decode(encrypted);
    final nonce = combined.sublist(0, AppConstants.nonceLength);
    final macBytes = combined.sublist(combined.length - _macLength);
    final cipherText = combined.sublist(
      AppConstants.nonceLength,
      combined.length - _macLength,
    );
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final plain = await _aesGcm.decrypt(box, secretKey: kek);
    return SecretKey(Uint8List.fromList(plain));
  }

  /// 从密码派生密钥
  Future<SecretKey> deriveKey(String password, Uint8List salt) async {
    return _argon2id.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt.toList(),
    );
  }

  /// 生成验证哈希
  Future<String> generateVerifyHash(SecretKey key) async {
    const verifyPlain = 'LOCAL_PWD_VERIFY';
    final nonce = _generateNonce();
    final box = await _aesGcm.encrypt(
      utf8.encode(verifyPlain),
      secretKey: key,
      nonce: nonce,
    );
    final combined = <int>[...box.nonce, ...box.cipherText, ...box.mac.bytes];
    return base64Encode(combined);
  }

  /// 校验密码
  Future<bool> verifyKey(SecretKey key, String verifyHash) async {
    try {
      final combined = base64Decode(verifyHash);
      final nonce = combined.sublist(0, AppConstants.nonceLength);
      final macBytes = combined.sublist(combined.length - _macLength);
      final cipherText = combined.sublist(
        AppConstants.nonceLength,
        combined.length - _macLength,
      );
      final box = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
      final plain = await _aesGcm.decrypt(box, secretKey: key);
      return utf8.decode(plain) == 'LOCAL_PWD_VERIFY';
    } catch (_) {
      return false;
    }
  }

  /// 加密 JSON 数据
  Future<String> encryptJson(Map<String, dynamic> data, SecretKey key) async {
    final jsonStr = jsonEncode(data);
    final nonce = _generateNonce();
    final box = await _aesGcm.encrypt(
      utf8.encode(jsonStr),
      secretKey: key,
      nonce: nonce,
    );
    final combined = <int>[...box.nonce, ...box.cipherText, ...box.mac.bytes];
    return base64Encode(combined);
  }

  /// 解密 JSON 数据
  Future<Map<String, dynamic>> decryptJson(String encrypted, SecretKey key) async {
    final combined = base64Decode(encrypted);
    final nonce = combined.sublist(0, AppConstants.nonceLength);
    final macBytes = combined.sublist(combined.length - _macLength);
    final cipherText = combined.sublist(
      AppConstants.nonceLength,
      combined.length - _macLength,
    );
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final plain = await _aesGcm.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }

  /// 从 SecretKey 提取原始字节
  Future<Uint8List> extractKeyBytes(SecretKey key) async {
    return Uint8List.fromList(await key.extractBytes());
  }

  /// 从字节重建 SecretKey
  SecretKey fromBytes(Uint8List bytes) {
    return SecretKey(bytes);
  }
}
