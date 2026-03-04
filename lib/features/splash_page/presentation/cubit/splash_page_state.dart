part of 'splash_page_cubit.dart';

abstract class SplashPageState extends Equatable {
  const SplashPageState();

  @override
  List<Object> get props => [];
}

class SplashPageInitial extends SplashPageState {}

class SplashLoading extends SplashPageState {}

class SplashAuthenticated extends SplashPageState {}

class SplashUnauthenticated extends SplashPageState {}
