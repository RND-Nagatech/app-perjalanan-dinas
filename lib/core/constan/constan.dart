enum Environment { development, qc, production }

class ApiConfig {
  final Environment env;

  const ApiConfig._(this.env);

  static const ApiConfig development = ApiConfig._(Environment.development);
  static const ApiConfig qc = ApiConfig._(Environment.qc);
  static const ApiConfig production = ApiConfig._(Environment.production);

  /// Set the active config at app startup (override as needed)
  static ApiConfig current = development;

  String get baseUrl {
    switch (env) {
      case Environment.development:
        return 'http://192.168.110.45:5001/api';
      case Environment.qc:
        return 'https://api.qc.example.com';
      case Environment.production:
        return 'https://api.example.com';
    }
  }

  Duration get requestTimeout => const Duration(seconds: 30);

  Map<String, String> headers({String? bearerToken}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }
    return headers;
  }

  String endpoint(String path) {
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleaned';
  }

  // Auth endpoints
  String get authLoginURL => '/auth/login';
  // Register endpoint
  String get authRegisterURL => '/auth/register';
  // Perjalanan endpoint
  String get perjalananURL => '/perjalanan-dinas';

  /// Perjalanan items path, /perjalanan-dinas/{id}/items
  String perjalananItemsPath(String perjalananId) =>
      '$perjalananURL/$perjalananId/items';
}

// Convenience top-level getters
Environment get currentEnvironment => ApiConfig.current.env;
String apiBaseUrl() => ApiConfig.current.baseUrl;
Map<String, String> apiHeaders({String? token}) =>
    ApiConfig.current.headers(bearerToken: token);
String apiEndpoint(String path) => ApiConfig.current.endpoint(path);
