import '../repositories/home_repository.dart';

class GetTotalTransaksi {
  final HomeRepository repository;
  GetTotalTransaksi(this.repository);

  Future<int?> call() async {
    return repository.getTotalTransaksi();
  }
}
