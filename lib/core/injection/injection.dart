import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../network/dio_client.dart';

final GetIt sl = GetIt.instance;

Future<void> initCoreModule() async {
  //SharedPreferences dulu
  if (!sl.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  }

  // DioClient (yang ada interceptor)
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(
      () => DioClient(sl<SharedPreferences>()),
    );
  }

  // Register Dio dari DioClient
  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);
  }

}
