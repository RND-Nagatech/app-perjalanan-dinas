class AuthFailure implements Exception {
  final String message;
  AuthFailure([this.message = 'An unknown authentication error occurred']);

  @override
  String toString() => 'AuthFailure: $message';
}
