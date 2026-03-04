import '../repositories/home_repository.dart';

class GetSisaDana {
  final HomeRepository repository;
  GetSisaDana(this.repository);

  Future<int?> call() async {
    return repository.getSisaDana();
  }
}
