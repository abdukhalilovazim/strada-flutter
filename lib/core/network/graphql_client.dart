import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/network/signature_link.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';

GraphQLClient buildGraphQLClient({String? token}) {
  // ORDER API ga yuborilishi kerak bo'lgan operatsiya nomlari
  const orderOperations = {'orders', 'order', 'createOrder', 'checkPromoCode'};

  final splitLink = Link.split(
    (request) => orderOperations.contains(request.operation.operationName),
    _buildHttpLink(ApiConstants.orderEndpoint,  token: token),
    _buildHttpLink(ApiConstants.commonEndpoint, token: token),
  );

  final loggingLink = Link.function((request, [forward]) {
    debugPrint('🚀 [GraphQL Request] ${request.operation.operationName}');
    debugPrint('   Variables: ${request.variables}');
    return forward!(request).map((response) {
      debugPrint('✅ [GraphQL Response] ${request.operation.operationName}');
      debugPrint('   Data: ${response.data}');
      if (response.errors != null) {
        debugPrint('❌ [GraphQL Errors] ${response.errors}');
      }
      return response;
    });
  });

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: Link.from([loggingLink, SignatureLink(), splitLink]),
  );
}

HttpLink _buildHttpLink(String url, {String? token}) {
  final context = AppConstants.navigatorKey.currentContext;
  final languageCode = context != null ? EasyLocalization.of(context)?.locale.languageCode : 'uz';

  return HttpLink(
    url,
    defaultHeaders: {
      if (token != null) 'Authorization': 'Bearer $token',
      'Language': languageCode ?? 'uz',
      'device_id': DeviceInfoHelper.deviceId,
      'device_name': DeviceInfoHelper.deviceName,
      'Source': Platform.isIOS ? 'ios' : 'android',
      'device': Platform.isIOS ? 'ios' : 'android',
    },
  );
}
