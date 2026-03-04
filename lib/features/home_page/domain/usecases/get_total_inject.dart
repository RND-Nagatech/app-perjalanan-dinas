import '../repositories/home_repository.dart';

class GetTotalInject {
  final HomeRepository repository;
  GetTotalInject(this.repository);

  Future<int?> call() async {
    return repository.getTotalInject();
  }
}
