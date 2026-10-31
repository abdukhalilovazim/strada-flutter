import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/core/network/api_client.dart';

/// REST API xatolarini [Failure]ga aylantirish uchun helper.
class ApiHelper {
  static Failure fromException(Object e) {
    if (e is ApiException) {
      return ServerFailure(message: e.message);
    }
    return ServerFailure(message: e.toString());
  }
}
