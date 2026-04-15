import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/error/failures.dart';

/// Barcha GraphQL xatolarini bir xil formatda qayta ishlash uchun helper.
///
/// Backend xato formati:
/// ```json
/// { "errors": [{ "message": "..." }] }
/// ```
class GraphQLHelper {
  /// [OperationException]dan birinchi xato xabarini oladi.
  ///
  /// - GraphQL server xatosi (errors[0].message) → qiymatini to'g'ridan-to'g'ri qaytaradi.
  /// - HTTP/Network xatosi → umumiy xabar qaytaradi.
  static String extractMessage(OperationException e) {
    if (e.graphqlErrors.isNotEmpty) {
      return e.graphqlErrors.first.message;
    }
    final link = e.linkException;
    if (link is HttpLinkServerException) {
      return 'Server xatosi (HTTP ${link.response.statusCode})';
    }
    if (link is NetworkException) {
      return link.message ?? 'Tarmoq xatosi yuz berdi';
    }
    return 'Noma\'lum xato yuz berdi';
  }

  /// [OperationException]ni tegishli [Failure]ga aylantiradi.
  static Failure toFailure(OperationException e) {
    if (e.linkException is NetworkException) {
      return ServerFailure(message: extractMessage(e));
    }
    return ServerFailure(message: extractMessage(e));
  }

  /// [dynamic] xatoni [Failure]ga xavfsiz aylantiradi.
  static Failure fromException(Object e) {
    if (e is OperationException) return toFailure(e);
    return ServerFailure(message: e.toString());
  }
}
