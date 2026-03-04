import '../repositories/auth_repository.dart';

class ClearSavedCredentialsUseCase {
  final AuthRepository repository;

  ClearSavedCredentialsUseCase(this.repository);

  Future<void> call() => repository.clearRememberedCredentialsIfNeeded();
}
