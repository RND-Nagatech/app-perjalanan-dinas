class AuthRemoteException implements Exception {
  final String message;
  AuthRemoteException(this.message);

  @override
  String toString() => 'AuthRemoteException: $message';
}
