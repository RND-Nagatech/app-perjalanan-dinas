import '../repositories/home_repository.dart';

class ToggleSpdSubscription {
  final HomeRepository repository;
  ToggleSpdSubscription(this.repository);

  Future<bool> call(bool currentlySubscribed) => repository.toggleSpdSubscription(currentlySubscribed);
}
