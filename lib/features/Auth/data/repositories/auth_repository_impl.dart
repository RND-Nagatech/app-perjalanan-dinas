import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/failures/auth_failure.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';
import '../exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences prefs;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  AuthRepositoryImpl(this.remoteDataSource, this.prefs);

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final UserModel userModel = await remoteDataSource.login(email, password);

      //Simpan token (WAJIB ADA)
      await prefs.setString(_tokenKey, userModel.token);

      //Simpan user TANPA token (biar clean)
      await prefs.setString(
        _userKey,
        jsonEncode({
          "uid": userModel.uid,
          "email": userModel.email,
          "name": userModel.name,
        }),
      );

      // Also save explicit user id for quick access by other modules
      await prefs.setString('auth_user_id', userModel.uid);

      return userModel;
    } on AuthRemoteException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure("Terjadi kesalahan saat login");
    }
  }

  @override
  Future<void> logout() async {
    try {
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove('auth_user_id');
    } catch (e) {
      throw AuthFailure("Gagal logout");
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final token = prefs.getString(_tokenKey);
      final userRaw = prefs.getString(_userKey);

      if (token == null || userRaw == null) {
        return null;
      }

      final Map<String, dynamic> userMap = jsonDecode(userRaw);

      return UserModel(
        uid: userMap['uid'],
        email: userMap['email'],
        name: userMap['name'],
        token: token,
      );
    } catch (e) {
      throw AuthFailure("Gagal mengambil user");
    }
  }

  @override
  Future<void> register(String email, String password, {String? name}) async {
    try {
      await remoteDataSource.register(email, password, name);
      return;
    } on AuthRemoteException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure("Terjadi kesalahan saat register");
    }
  }

  @override
  Future<void> clearRememberedCredentialsIfNeeded() async {
    try {
      final saved = prefs.getBool('remember_me') ?? false;
      if (!saved) {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }
    } catch (e) {
      throw AuthFailure("Gagal membersihkan kredensial");
    }
  }
}
