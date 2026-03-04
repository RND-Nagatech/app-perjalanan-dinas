import 'package:trips_apps/features/perjalanan/domain/repositories/perjalanan_repository.dart';

/// Usecase to trigger a refresh of perjalanan data.
class RefreshPerjalananUseCase {
  final PerjalananRepository repository;
  RefreshPerjalananUseCase(this.repository);

  Future<void> call() => repository.refreshPerjalanan();
}
