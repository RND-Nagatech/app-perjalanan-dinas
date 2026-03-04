import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constan/constan.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioClient {
  final Dio dio;
  final SharedPreferences prefs;

  static const _tokenKey = 'auth_token';

  DioClient(this.prefs)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.current.baseUrl,
          connectTimeout: ApiConfig.current.requestTimeout,
          receiveTimeout: ApiConfig.current.requestTimeout,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      ) {
    _addInterceptors();
  }

  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = prefs.getString(_tokenKey);

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Optional: auto logout
            await prefs.remove(_tokenKey);
          }
          return handler.next(e);
        },
      ),
    );

    if (ApiConfig.current.env == Environment.development) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }
  }
}
