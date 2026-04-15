import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/io_client.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';

GraphQLClient buildGraphQLClient({String? token}) {
  // ORDER API ga yuborilishi kerak bo'lgan operatsiya nomlari
  const orderOperations = {
    'orders',
    'Orders',
    'order',
    'Order',
    'createOrder',
    'checkPromoCode',
    'CheckPromoCode',
    'calculateDeliveryPrice',
    'CalculateDeliveryPrice',
  };

  final httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);
  final ioClient = IOClient(httpClient);

  // 30 soniyalik timeout o'rnatildi (avval timeout aniqlanmagan edi)
  final httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 30);

  final httpLink = Link.split(
    (request) => orderOperations.contains(request.operation.operationName),
    HttpLink(ApiConstants.orderEndpoint, httpClient: httpClient),
    HttpLink(ApiConstants.commonEndpoint, httpClient: httpClient),
    HttpLink(ApiConstants.orderEndpoint, httpClient: ioClient),
    HttpLink(ApiConstants.commonEndpoint, httpClient: ioClient),
  );

  final link = Link.function((request, [forward]) {
    final definitions = request.operation.document.definitions.whereType<OperationDefinitionNode>();
    final isMutation = definitions.any((d) => d.type == OperationType.mutation);

    // 1. Auth & Localization Logic
    final context = AppConstants.navigatorKey.currentContext;
    final languageCode = context != null ? EasyLocalization.of(context)?.locale.languageCode : 'uz';

    var updatedReq = request.updateContextEntry<HttpLinkHeaders>(
      (h) => HttpLinkHeaders(headers: {
        ...(h?.headers ?? {}),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'PizzaStrada/${Platform.isIOS ? "iOS" : "Android"} Mobile App',
        if (token != null) 'Authorization': 'Bearer $token',
        'language': languageCode ?? 'uz',
        'device-id': DeviceInfoHelper.deviceId,
        'device-name': DeviceInfoHelper.deviceName,
        'device': Platform.isIOS ? 'ios' : 'android',
      }),
    );

    // 2. Signature Logic (formerly SignatureLink)
    if (isMutation) {
      final variables = updatedReq.variables;
      final jsonStr = jsonEncode(variables);
      final randomStr = _generateRandomStr(16);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final payload = '$jsonStr$randomStr$timestamp';
      final hmac = Hmac(sha256, utf8.encode(ApiConstants.hmacSecret));
      final sign = hmac.convert(utf8.encode(payload)).toString();

      updatedReq = updatedReq.updateContextEntry<HttpLinkHeaders>(
        (h) => HttpLinkHeaders(headers: {
          ...(h?.headers ?? {}),
          'Header-Random-Str': randomStr,
          'Header-Timestamp': timestamp,
          'Header-Sign': sign,
        }),
      );
    }

    // 3. Logging Logic (Passive)
    final isOrder = orderOperations.contains(updatedReq.operation.operationName);
    debugPrint('🚀 [GraphQL Request] [${isOrder ? "ORDER" : "COMMON"}] ${updatedReq.operation.operationName}');

    return forward!(updatedReq);
  }).concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: link,
  );
}

String _generateRandomStr(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}
