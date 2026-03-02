import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage using flutter_secure_storage.
/// Falls back to in-memory storage on macOS debug (keychain unavailable).
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  // In-memory fallback for macOS debug where keychain is unavailable
  static final Map<String, String> _memoryStore = {};
  static bool get _useMemory => !kIsWeb && Platform.isMacOS && kDebugMode;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Save both access and refresh tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_useMemory) {
      _memoryStore[_accessTokenKey] = accessToken;
      _memoryStore[_refreshTokenKey] = refreshToken;
      return;
    }
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Get access token.
  Future<String?> getAccessToken() async {
    if (_useMemory) return _memoryStore[_accessTokenKey];
    return _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token.
  Future<String?> getRefreshToken() async {
    if (_useMemory) return _memoryStore[_refreshTokenKey];
    return _storage.read(key: _refreshTokenKey);
  }

  /// Check if tokens exist.
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Clear all tokens (logout).
  Future<void> clearTokens() async {
    if (_useMemory) {
      _memoryStore.clear();
      return;
    }
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
