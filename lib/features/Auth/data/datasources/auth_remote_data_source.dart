import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../exceptions.dart';
import '../../../../core/constan/constan.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> register(String email, String password, String? name);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        ApiConfig.current.authLoginURL,
        data: {"email": email, "password": password},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return UserModel.fromJson(data);
      } else {
        throw AuthRemoteException(
          'Login failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw AuthRemoteException(
          'Waktu tunggu respons server habis. Coba lagi atau periksa koneksi.',
        );
      }

      throw AuthRemoteException(
        e.response?.data?['message']?.toString() ??
            'Terjadi kesalahan saat login',
      );
    }
  }

  @override
  Future<void> register(String email, String password, String? name) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {"email": email, "password": password, "name": name},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw AuthRemoteException(
        'Register failed with status ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw AuthRemoteException(
        e.response?.data?['message']?.toString() ?? 'Register gagal',
      );
    } catch (e) {
      throw AuthRemoteException('Register gagal');
    }
  }
}
