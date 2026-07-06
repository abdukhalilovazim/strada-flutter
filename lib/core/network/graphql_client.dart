import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/network/cookie_aware_client.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';

/// ORDER API operatsiya nomlari — routing uchun
const _orderOperations = {
  'orders', 'Orders',
  'order', 'Order',
  'createOrder', 'CreateOrder',
  'checkPromoCode', 'CheckPromoCode',
};

/// GraphQL client yaratish. Token har bir so'rovda dynamic olinadi.
GraphQLClient buildGraphQLClient() {
  // --- Cookie-aware HTTP Client: Imunify360 warm-up + 60s timeout ---
  final cookieClient = CookieAwareClient();

  // --- HTTP Link: order vs common routing ---
  final httpLink = Link.split(
    (req) => _orderOperations.contains(req.operation.operationName),
    HttpLink(ApiConstants.orderEndpoint, httpClient: cookieClient),
    HttpLink(ApiConstants.commonEndpoint, httpClient: cookieClient),
  );

  // --- Birlashtirilgan Link: Auth + Signature + Logging ---
  final combinedLink = Link.function((request, [forward]) async* {
    final token = await SecureStorage.getToken();
    final definitions = request.operation.document.definitions
        .whereType<OperationDefinitionNode>();
    final isMutation = definitions.any((d) => d.type == OperationType.mutation);

    // 1. Headers: Auth, Localization, Device
    final context = AppConstants.navigatorKey.currentContext;
    final lang = (context != null && context.mounted)
        ? (EasyLocalization.of(context)?.locale.languageCode ?? 'uz')
        : 'uz';

    var req = request.updateContextEntry<HttpLinkHeaders>(
      (h) => HttpLinkHeaders(headers: {
        ...(h?.headers ?? {}),
        // App-specific headers
        if (token != null) 'Authorization': 'Bearer $token',
        'language': lang,
        'device-id': DeviceInfoHelper.deviceId,
        'device-name': DeviceInfoHelper.deviceName,
        'device': Platform.isIOS ? 'ios' : 'android',
        'app-version-code': DeviceInfoHelper.appVersionCode,
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

      // 1. GraphQL Validation yoki Auth xatolarini Telegramga yuborish
      if (response.errors != null && response.errors!.isNotEmpty) {
        _sendErrorToTelegram(
          type: 'GraphQL Error',
          operationName: req.operation.operationName ?? 'unnamed',
          variables: req.variables,
          errorDetails: response.errors!.map((err) => err.message).join('\n'),
        );
      }

      return response;
    }).handleError((error) {
      // 2. Tarmoq va Ulanish xatolarini (Timeout, SocketException va b.) Telegramga yuborish
      _sendErrorToTelegram(
        type: 'Network / Connection Error',
        operationName: req.operation.operationName ?? 'unnamed',
        variables: req.variables,
        errorDetails: error.toString(),
      );
      throw error;
    });
  }).concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: combinedLink,
  );
}

/// Xatoliklarni Telegram bot orqali guruh yoki shaxsiy chatga yuboruvchi yordamchi funksiya
void _sendErrorToTelegram({
  required String type,
  required String operationName,
  required Map<String, dynamic> variables,
  required String errorDetails,
}) async {
  try {
    final botToken = dotenv.maybeGet('TELEGRAM_BOT_TOKEN');
    final chatId = dotenv.maybeGet('TELEGRAM_CHAT_ID');

    // Agar tokenlar bo'sh bo'lsa, xatolik chiqarmasdan jimgina qaytadi
    if (botToken == null || chatId == null || botToken.isEmpty || chatId.isEmpty) {
      return;
    }

    final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
    final environment = dotenv.get('ENVIRONMENT', fallback: 'dev');

    // HTML-safe escape: Telegram Markdown special chars crash'ini oldini oladi
    String escapeHtml(String text) =>
        text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

    final safeVars = escapeHtml(jsonEncode(variables));
    final safeError = escapeHtml(errorDetails);

    final message = '🚨 <b>Pizza Strada Mobile API Error</b>\n'
        '🌐 <b>Env:</b> $environment\n'
        '📌 <b>Type:</b> $type\n'
        '🔍 <b>Operation:</b> $operationName\n'
        '⚙️ <b>Variables:</b> <code>$safeVars</code>\n\n'
        '⚠️ <b>Error Details:</b>\n'
        '<pre>$safeError</pre>';

    final client = HttpClient();
    final request = await client.postUrl(url);
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.write(jsonEncode({
      'chat_id': chatId,
      'text': message,
      'parse_mode': 'HTML',
    }));
    
    final response = await request.close();
    // Resurslarni bo'shatish uchun response o'qib tugatiladi
    await response.transform(utf8.decoder).join();
    client.close();
  } catch (e) {
    debugPrint('Failed to send error to Telegram: $e');
  }
}

/// Kriptografik xavfsiz random string (signature uchun)
String _randomStr(int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}
