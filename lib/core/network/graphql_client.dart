import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/io_client.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';

/// ORDER API operatsiya nomlari — routing uchun
const _orderOperations = {
  'orders', 'Orders',
  'order', 'Order',
  'createOrder',
  'checkPromoCode', 'CheckPromoCode',
};

/// GraphQL client yaratish. Token har bir so'rovda dynamic olinadi.
GraphQLClient buildGraphQLClient() {
  // --- HTTP Client: 30 soniyalik timeout ---
  final ioClient = IOClient(
    HttpClient()
      ..connectionTimeout = const Duration(seconds: 60)
      ..idleTimeout = const Duration(seconds: 60),
  );

  // --- HTTP Link: order vs common routing ---
  final httpLink = Link.split(
    (req) => _orderOperations.contains(req.operation.operationName),
    HttpLink(ApiConstants.orderEndpoint, httpClient: ioClient),
    HttpLink(ApiConstants.commonEndpoint, httpClient: ioClient),
  );

  // --- Birlashtirilgan Link: Auth + Signature + Logging ---
  final combinedLink = Link.function((request, [forward]) async* {
    final token = await SecureStorage.getToken();
    final definitions = request.operation.document.definitions
        .whereType<OperationDefinitionNode>();
    final isMutation = definitions.any((d) => d.type == OperationType.mutation);

    // 1. Headers: Auth, Localization, Device
    final context = AppConstants.navigatorKey.currentContext;
    final lang = context != null
        ? (EasyLocalization.of(context)?.locale.languageCode ?? 'uz')
        : 'uz';

    var req = request.updateContextEntry<HttpLinkHeaders>(
      (h) => HttpLinkHeaders(headers: {
        ...(h?.headers ?? {}),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'PizzaStrada/${Platform.isIOS ? "iOS" : "Android"} Mobile App',
        if (token != null) 'Authorization': 'Bearer $token',
        'language': lang,
        'device-id': DeviceInfoHelper.deviceId,
        'device-name': DeviceInfoHelper.deviceName,
        'device': Platform.isIOS ? 'ios' : 'android',
      }),
    );

    // 2. Signature headers (faqat mutation uchun)
    if (isMutation) {
      final randomStr = _randomStr(16);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final payload = '${jsonEncode(req.variables)}$randomStr$timestamp';
      final sign = Hmac(sha256, utf8.encode(ApiConstants.hmacSecret))
          .convert(utf8.encode(payload))
          .toString();

      req = req.updateContextEntry<HttpLinkHeaders>(
        (h) => HttpLinkHeaders(headers: {
          ...(h?.headers ?? {}),
          'Header-Random-Str': randomStr,
          'Header-Timestamp': timestamp,
          'Header-Sign': sign,
        }),
      );
    }

    // 3. Logging (faqat debug mode da)
    if (kDebugMode) {
      final schema = _orderOperations.contains(req.operation.operationName)
          ? 'ORDER'
          : 'COMMON';
      final operationName = req.operation.operationName ?? 'unnamed';
      final variables = const JsonEncoder.withIndent('  ').convert(req.variables);

      debugPrint('┌──────────────────────────────────────────────────────────────────');
      debugPrint('│ 🚀 [GraphQL REQUEST] [$schema]');
      debugPrint('│ Operation: $operationName');
      debugPrint('│ Context: $variables');
      debugPrint('└──────────────────────────────────────────────────────────────────');
    }

    yield* forward!(req).map((response) {
      if (kDebugMode) {
        final schema = _orderOperations.contains(req.operation.operationName)
            ? 'ORDER'
            : 'COMMON';
        final operationName = req.operation.operationName ?? 'unnamed';
        
        debugPrint('┌──────────────────────────────────────────────────────────────────');
        if (response.errors != null && response.errors!.isNotEmpty) {
          debugPrint('│ ❌ [GraphQL ERROR] [$schema] $operationName');
          final errors = const JsonEncoder.withIndent('  ').convert(response.errors);
          debugPrint('│ Errors: $errors');
        } else {
          debugPrint('│ ✅ [GraphQL RESPONSE] [$schema] $operationName');
          // Faqat kichikroq datalarni yoki bir qismini chiqarish (log to'lib ketmasligi uchun)
          final data = const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('│ Data: ${data.length > 1000 ? "${data.substring(0, 1000)}..." : data}');
        }
        debugPrint('└──────────────────────────────────────────────────────────────────');
      }
      return response;
    });
  }).concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: combinedLink,
  );
}

/// Kriptografik xavfsiz random string (signature uchun)
String _randomStr(int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}
