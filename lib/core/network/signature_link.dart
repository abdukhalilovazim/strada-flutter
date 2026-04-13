import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:gql/ast.dart';

class SignatureLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final isMutation = request.operation.document.definitions
        .whereType<OperationDefinitionNode>()
        .any((d) => d.type == OperationType.mutation);

    if (isMutation) {
      final variables  = Map<String, dynamic>.from(request.variables);
      final sortedKeys = variables.keys.toList()..sort();               // ksort
      final sortedVars = {for (var k in sortedKeys) k: variables[k]};
      final jsonStr    = jsonEncode(sortedVars);

      final randomStr  = _generateRandomStr(16);
      final timestamp  = DateTime.now().millisecondsSinceEpoch.toString();

      // values + uniqueToken + timestamp
      final payload    = '$jsonStr${ApiConstants.hmacSecret}$timestamp';
      final hmac       = Hmac(sha256, utf8.encode(ApiConstants.hmacSecret));
      final sign       = hmac.convert(utf8.encode(payload)).toString();

      final updatedReq = request.updateContextEntry<HttpLinkHeaders>(
        (h) => HttpLinkHeaders(headers: {
          ...(h?.headers ?? {}),
          'Header-Random-Str': randomStr,
          'Header-Timestamp':  timestamp,
          'Header-Sign':       sign,
        }),
      );
      yield* forward!(updatedReq);
    } else {
      yield* forward!(request);
    }
  }

  String _generateRandomStr(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
