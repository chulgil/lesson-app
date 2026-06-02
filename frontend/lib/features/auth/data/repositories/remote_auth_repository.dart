import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Remote implementation of [AuthRepository] using FastAPI backend.
class RemoteAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  RemoteAuthRepository(this._apiClient, this._tokenStorage);

  @override
  Future<TokenPair> loginWithOAuth({
    required String provider,
    required String idToken,
  }) async {
    final response = await _apiClient.post(
      '/auth/oauth/$provider',
      data: {
        'provider': provider,
        'code': idToken, // serverAuthCode from Google Sign-In
      },
    );
    return TokenPair.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TokenPair> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      '/auth/token/refresh',
      data: {'refresh_token': refreshToken},
    );
    return TokenPair.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<({TokenPair tokens, AuthUser user})> devLogin({
    required String email,
    required String role,
    String? name,
  }) async {
    final response = await _apiClient.post(
      '/auth/dev-login',
      data: {'email': email, 'role': role, if (name != null) 'name': name},
    );
    final data = response.data as Map<String, dynamic>;
    final tokens = TokenPair.fromJson(data);
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    return (tokens: tokens, user: user);
  }

  @override
  Future<AuthUser> getMe() async {
    final response = await _apiClient.get('/auth/me');
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthUser> updateRole(String role) async {
    final response = await _apiClient.patch('/auth/me', data: {'role': role});
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthUser> acceptTerms({required bool marketingConsent}) async {
    final response = await _apiClient.post(
      '/auth/consent',
      data: {'marketing_consent': marketingConsent},
    );
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    await _apiClient.post(
      '/auth/logout',
      data: {if (refreshToken != null) 'refresh_token': refreshToken},
    );
  }
}
