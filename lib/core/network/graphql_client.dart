import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        'User-Agent': Platform.isIOS
            ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1'
            : 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
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

    final message = '''
🚨 *Pizza Strada Mobile API Error*
🌐 *Env:* $environment
📌 *Type:* $type
🔍 *Operation:* $operationName
⚙️ *Variables:* `${jsonEncode(variables)}`

⚠️ *Error Details:*
```
$errorDetails
```
''';

    final client = HttpClient();
    final request = await client.postUrl(url);
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'chat_id': chatId,
      'text': message,
      'parse_mode': 'Markdown',
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
