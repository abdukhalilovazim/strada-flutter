import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  ApiClient get client => ApiClient();
}

