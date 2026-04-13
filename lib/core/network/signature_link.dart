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
      final variables = request.variables;
      // AGENTS.md: variables JSON formatida, unicode va slashlar escape qilinmagan bo'lishi kerak
      // Dart'da standard jsonEncode unicode'ni escape qiladi (\uXXXX). 
      // Agar backend raw unicode kutayotgan bo'lsa, bu yerda qo'shimcha ishlov berish kerak bo'lishi mumkin.
      final jsonStr = jsonEncode(variables);

      final randomStr = _generateRandomStr(16);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // AGENTS.md: String stringToHash = jsonEncode(variables) + randomStr + timestamp;
      final payload = '$jsonStr$randomStr$timestamp';
      
      final hmac = Hmac(sha256, utf8.encode(ApiConstants.hmacSecret));
      final sign = hmac.convert(utf8.encode(payload)).toString();

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
