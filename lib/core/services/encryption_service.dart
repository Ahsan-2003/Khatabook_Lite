import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;

  static const String _keySaltKey = 'encryption_salt';

  // Initialize encryption
  Future<void> initialize() async {
    final salt = await _getOrCreateSalt();
    final key = encrypt.Key.fromUtf8(_generateKey(salt));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    _key = key;
    _iv = iv;
    _encrypter = encrypter;
  }

  // Get or create salt
  Future<String> _getOrCreateSalt() async {
    final prefs = await SharedPreferences.getInstance();
    var salt = prefs.getString(_keySaltKey);

    if (salt == null) {
      salt = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_keySaltKey, salt);
    }

    return salt;
  }

  // Generate key from salt using SHA-256
  String _generateKey(String salt) {
    final bytes = utf8.encode(salt);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  // Encrypt string
  String encryptString(String plainText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
    return encrypted.base64;
  }

  // Decrypt string
  String decryptString(String encryptedText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    return _encrypter!.decrypt64(encryptedText, iv: _iv!);
  }

  // Encrypt map (for JSON)
  Map<String, dynamic> encryptMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String) {
        return MapEntry(key, encryptString(value));
      }
      return MapEntry(key, value);
    });
  }

  // Decrypt map
  Map<String, dynamic> decryptMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String) {
        try {
          return MapEntry(key, decryptString(value));
        } catch (e) {
          return MapEntry(key, value);
        }
      }
      return MapEntry(key, value);
    });
  }
}
