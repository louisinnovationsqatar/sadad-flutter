// Built by Louis Innovations (www.louis-innovations.com)

import 'package:flutter/foundation.dart';
import 'package:sadad_qatar/sadad_qatar.dart';

/// Result delivered to [SadadCheckoutButton.onSuccess] after a successful payment.
class SadadPaymentResult {
  /// `true` when `RESPCODE == '1'` in the SADAD callback.
  final bool isSuccess;

  /// The merchant order ID echoed back by SADAD.
  final String orderNumber;

  /// The SADAD gateway transaction reference number.
  final String transactionNumber;

  /// The transaction amount in QAR.
  final double amount;

  /// SADAD response code (e.g. `'1'` for success).
  final String responseCode;

  /// Human-readable response message from SADAD.
  final String responseMessage;

  /// Raw transaction status string from the callback.
  final String status;

  const SadadPaymentResult({
    required this.isSuccess,
    required this.orderNumber,
    required this.transactionNumber,
    required this.amount,
    required this.responseCode,
    required this.responseMessage,
    required this.status,
  });

  /// Constructs a [SadadPaymentResult] from a [CallbackResult] returned by
  /// the `sadad_qatar` SDK callback handler.
  factory SadadPaymentResult.fromCallbackResult(CallbackResult result) {
    return SadadPaymentResult(
      isSuccess: result.isSuccess,
      orderNumber: result.orderNumber,
      transactionNumber: result.transactionNumber,
      amount: result.amount,
      responseCode: result.responseCode,
      responseMessage: result.responseMessage,
      status: result.status,
    );
  }

  /// Constructs a [SadadPaymentResult] from the raw URL query parameters
  /// that SADAD appends to the callback URL after a redirect checkout.
  ///
  /// Handles both `RESPCODE` and `STATUS` fields from the SADAD callback.
  factory SadadPaymentResult.fromQueryParameters(
    Map<String, String> params,
  ) {
    final responseCode = params['RESPCODE'] ?? params['respcode'] ?? '';
    final status = params['STATUS'] ?? params['status'] ?? '';
    final amount = double.tryParse(
          params['TXNAMOUNT'] ?? params['txnamount'] ?? '0',
        ) ??
        0.0;

    return SadadPaymentResult(
      isSuccess: responseCode == '1',
      orderNumber: params['ORDERID'] ?? params['orderid'] ?? '',
      transactionNumber: params['TXNID'] ?? params['txnid'] ?? '',
      amount: amount,
      responseCode: responseCode,
      responseMessage: params['RESPMSG'] ?? params['respmsg'] ?? '',
      status: status,
    );
  }

  @override
  String toString() =>
      'SadadPaymentResult(isSuccess: $isSuccess, orderNumber: $orderNumber, '
      'transactionNumber: $transactionNumber, amount: $amount, '
      'responseCode: $responseCode, status: $status)';
}

/// Manages the SADAD checkout flow for Flutter applications.
///
/// Handles building checkout form data from the `sadad_qatar` SDK and
/// provides helpers to detect and parse the SADAD callback URL after the
/// customer completes or cancels payment.
///
/// Typical usage:
/// ```dart
/// final manager = SadadCheckoutManager(config: config, version: 'v1.1');
/// final checkoutResult = manager.buildCheckout(orderData);
///
/// // Navigate to checkoutResult.url via WebView, then intercept:
/// if (manager.isCallbackUrl(navigationUrl)) {
///   final result = manager.parseCallbackUrl(navigationUrl);
///   if (result != null && result.isSuccess) { /* handle success */ }
/// }
/// ```
class SadadCheckoutManager {
  final SadadConfig config;

  /// Checkout version: `'v1.1'`, `'v2.1'`, or `'v2.2'`.
  final String version;

  late final SadadClient _client;

  SadadCheckoutManager({
    required this.config,
    this.version = 'v1.1',
  }) {
    _client = SadadClient(config);
  }

  /// Builds a [CheckoutResult] for the given [orderData] and [version].
  ///
  /// Throws [ArgumentError] for an unsupported [version].
  CheckoutResult buildCheckout(Map<String, dynamic> orderData) {
    return _client.checkout(orderData, version);
  }

  /// Returns `true` if [url] matches the configured SADAD callback URL,
  /// indicating that payment has completed (success or failure).
  ///
  /// Comparison is case-insensitive on the scheme and host. The path must
  /// start with the callback URL path.
  bool isCallbackUrl(String url) {
    final callbackUrl = config.callbackUrl;
    if (callbackUrl == null || callbackUrl.isEmpty) return false;

    try {
      final parsed = Uri.parse(url);
      final callback = Uri.parse(callbackUrl);

      final sameHost =
          parsed.host.toLowerCase() == callback.host.toLowerCase();
      final samePath =
          parsed.path.toLowerCase().startsWith(callback.path.toLowerCase());

      return sameHost && samePath;
    } catch (_) {
      return false;
    }
  }

  /// Parses a [callbackUrl] returned by SADAD and extracts the payment result.
  ///
  /// Returns `null` if the URL cannot be parsed or contains no SADAD parameters.
  SadadPaymentResult? parseCallbackUrl(String callbackUrl) {
    try {
      final uri = Uri.parse(callbackUrl);

      // Parameters may arrive as query params (GET redirect) or need to be
      // parsed from the fragment in some integration setups.
      final params = <String, String>{
        ...uri.queryParameters,
      };

      if (params.isEmpty) return null;

      // Verify at least a response code is present to confirm SADAD data.
      final hasRespCode =
          params.containsKey('RESPCODE') || params.containsKey('respcode');
      final hasStatus =
          params.containsKey('STATUS') || params.containsKey('status');

      if (!hasRespCode && !hasStatus) return null;

      return SadadPaymentResult.fromQueryParameters(params);
    } catch (e) {
      debugPrint('[SadadFlutter] Failed to parse callback URL: $e');
      return null;
    }
  }

  /// Builds a complete HTML page containing an auto-submitting form that
  /// posts the checkout parameters to the SADAD gateway.
  ///
  /// Use this HTML as the initial content of a [SadadWebView] for redirect
  /// modes (v1.1 and v2.1).
  String buildCheckoutHtml(Map<String, dynamic> orderData) {
    final result = buildCheckout(orderData);
    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Redirecting to SADAD...</title>
  <style>
    body { font-family: sans-serif; display: flex; align-items: center;
           justify-content: center; min-height: 100vh; margin: 0;
           background: #f5f5f5; }
    p { color: #555; font-size: 16px; }
  </style>
</head>
<body>
  <p>Redirecting to SADAD payment page...</p>
  ${result.toHtmlForm(formId: 'sadad-form', autoSubmit: true)}
</body>
</html>''';
  }
}
