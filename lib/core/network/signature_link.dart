import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:gql/ast.dart';

class SignatureLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final definitions = request.operation.document.definitions.whereType<OperationDefinitionNode>();
    final isMutation = definitions.any((d) => d.type == OperationType.mutation);

    if (isMutation) {
      final variables = request.variables;
      final jsonStr = jsonEncode(variables);
      final randomStr = _generateRandomStr(16);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final payload = '$jsonStr$randomStr$timestamp';
      final hmac = Hmac(sha256, utf8.encode(ApiConstants.hmacSecret));
      final sign = hmac.convert(utf8.encode(payload)).toString();

      final updatedReq = request.updateContextEntry<HttpLinkHeaders>(
        (h) => HttpLinkHeaders(headers: {
          ...(h?.headers ?? {}),
          'Header-Random-Str': randomStr,
          'Header-Timestamp': timestamp,
          'Header-Sign': sign,
        }),
      );
      return forward!(updatedReq);
    }
    
    return forward!(request);
  }

  String _generateRandomStr(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
