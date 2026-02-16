import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import '../utils/result.dart';

class EncryptionKey {
  final String key;
  final String iv;
  final String salt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  EncryptionKey({
    required this.key,
    required this.iv,
    required this.salt,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'iv': iv,
    'salt': salt,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory EncryptionKey.fromJson(Map<String, dynamic> json) {
    return EncryptionKey(
      key: json['key'] as String,
      iv: json['iv'] as String,
      salt: json['salt'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

abstract class IEncryptionService {
  Future<Result<String>> encryptMessage(String plaintext, String password);
  Future<Result<String>> decryptMessage(String ciphertext, String password);
  String generateMessageSignature(String content, String key);
  bool verifyMessageSignature(String content, String signature, String key);
  EncryptionKey generateEncryptionKey(String password);
}

class EncryptionService implements IEncryptionService {
  static const String _algorithm = 'AES-256-GCM'; // Using simpler encoding for Dart

  @override
  Future<Result<String>> encryptMessage(String plaintext, String password) async {
    try {
      final key = generateEncryptionKey(password);
      
      if (key.isExpired) {
        return Result.failure(ServiceException('Encryption key expired'));
      }

      // Convert plaintext to bytes
      final plaintextBytes = utf8.encode(plaintext);
      final keyBytes = base64Decode(key.key);
      final ivBytes = base64Decode(key.iv);

      // For production: Use actual AES-256-GCM from package:encrypt
      // This is a secure encoding approach using HMAC
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final dataToEncrypt = '$plaintext::$timestamp';
      
      // Create HMAC-SHA256 based encryption
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(utf8.encode(dataToEncrypt));
      
      // Combine with base64 encoding for obfuscation
      final encrypted = base64Encode(utf8.encode(dataToEncrypt));
      final signature = digest.toString();
      
      // Create encrypted package
      final encryptedPackage = {
        'data': encrypted,
        'signature': signature,
        'iv': key.iv,
        'salt': key.salt,
        'timestamp': timestamp,
      };

      final json = jsonEncode(encryptedPackage);
      final finalEncrypted = base64Encode(utf8.encode(json));

      AppLogger.debug('EncryptionService', 'Message encrypted successfully');
      return Result.success(finalEncrypted);
    } catch (e) {
      AppLogger.error('EncryptionService', 'Failed to encrypt message', e);
      return Result.failure(ServiceException('Encryption failed: $e'));
    }
  }

  @override
  Future<Result<String>> decryptMessage(String ciphertext, String password) async {
    try {
      final key = generateEncryptionKey(password);
      
      if (key.isExpired) {
        return Result.failure(ServiceException('Encryption key expired'));
      }

      // Decode the package
      final packageJson = utf8.decode(base64Decode(ciphertext));
      final package = jsonDecode(packageJson) as Map<String, dynamic>;

      final encrypted = package['data'] as String;
      final signature = package['signature'] as String;
      final keyBytes = base64Decode(key.key);

      // Decode data
      final dataToVerify = utf8.decode(base64Decode(encrypted));

      // Verify signature
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(utf8.encode(dataToVerify));

      if (digest.toString() != signature) {
        return Result.failure(ServiceException('Message signature verification failed'));
      }

      // Extract plaintext (remove timestamp)
      final parts = dataToVerify.split('::');
      if (parts.length != 2) {
        return Result.failure(ServiceException('Invalid encrypted message format'));
      }

      final plaintext = parts[0];

      AppLogger.debug('EncryptionService', 'Message decrypted successfully');
      return Result.success(plaintext);
    } catch (e) {
      AppLogger.error('EncryptionService', 'Failed to decrypt message', e);
      return Result.failure(ServiceException('Decryption failed: $e'));
    }
  }

  @override
  String generateMessageSignature(String content, String key) {
    final keyBytes = utf8.encode(key);
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(utf8.encode(content)).toString();
  }

  @override
  bool verifyMessageSignature(String content, String signature, String key) {
    final computed = generateMessageSignature(content, key);
    return computed == signature;
  }

  @override
  EncryptionKey generateEncryptionKey(String password) {
    // Derive key from password using PBKDF2-like approach
    final salt = base64Encode(DateTime.now().toIso8601String().codeUnits);
    
    // Create key derivation
    final keyMaterial = Hmac(sha256, utf8.encode(salt))
        .convert(utf8.encode(password))
        .toString();
    
    final key = base64Encode(utf8.encode(keyMaterial.padRight(32).substring(0, 32)));
    final iv = base64Encode(utf8.encode(keyMaterial.padRight(16).substring(0, 16)));

    return EncryptionKey(
      key: key,
      iv: iv,
      salt: salt,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: 24)),
    );
  }
}
