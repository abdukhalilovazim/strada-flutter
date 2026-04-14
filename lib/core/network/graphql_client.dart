import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/io_client.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/network/signature_link.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';

GraphQLClient buildGraphQLClient({String? token}) {
  // ORDER API ga yuborilishi kerak bo'lgan operatsiya nomlari
  const orderOperations = {'orders', 'order', 'createOrder', 'checkPromoCode'};

  final httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);
  final ioClient = IOClient(httpClient);

  final httpLink = Link.split(
    (request) => orderOperations.contains(request.operation.operationName),
    HttpLink(ApiConstants.orderEndpoint, httpClient: ioClient),
    HttpLink(ApiConstants.commonEndpoint, httpClient: ioClient),
  );

  final authLink = Link.function((request, [forward]) {
    final context = AppConstants.navigatorKey.currentContext;
    final languageCode = context != null ? EasyLocalization.of(context)?.locale.languageCode : 'uz';

    final updatedReq = request.updateContextEntry<HttpLinkHeaders>(
      (h) => HttpLinkHeaders(headers: {
        ...(h?.headers ?? {}),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        // Security360 firewall bypass — real brauzer User-Agent kerak
        'User-Agent': 'PizzaStrada/${Platform.isIOS ? "iOS" : "Android"} Mobile App',
        if (token != null) 'Authorization': 'Bearer $token',
        'language': languageCode ?? 'uz',
        'device-id': DeviceInfoHelper.deviceId,
        'device-name': DeviceInfoHelper.deviceName,
        'device': Platform.isIOS ? 'ios' : 'android',
      }),
    );
    return forward!(updatedReq);
  });

  final loggingLink = Link.function((request, [forward]) {
    final isOrder = orderOperations.contains(request.operation.operationName);
    final endpoint = isOrder ? 'ORDER' : 'COMMON';
    final url = isOrder ? ApiConstants.orderEndpoint : ApiConstants.commonEndpoint;

    debugPrint('🚀 [GraphQL Request] [$endpoint] ${request.operation.operationName}');
    debugPrint('   URL: $url');
    debugPrint('   Variables: ${request.variables}');

    return forward!(request).map((response) {
      if (response.errors != null) {
        debugPrint('❌ [GraphQL Errors] ${request.operation.operationName}: ${response.errors}');
      } else {
        debugPrint('✅ [GraphQL Response] ${request.operation.operationName}');
      }
      return response;
    });
  });

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: Link.from([loggingLink, authLink, SignatureLink(), httpLink]),
  );
}
