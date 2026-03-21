// Built by Louis Innovations (www.louis-innovations.com)

/// Flutter widget library for the SADAD Payment Gateway.
///
/// Provides ready-to-use Flutter widgets that wrap the `sadad_qatar` Dart SDK:
///
/// - [SadadCheckoutButton] — a "Pay with SADAD" button that handles the full
///   checkout flow, including WebView for redirect modes and embedded checkout
///   for v2.2.
/// - [SadadEmbeddedCheckout] — a WebView widget that loads the SADAD v2.2
///   embedded checkout and intercepts the callback URL.
/// - [SadadPaymentStatus] — a status-display widget with auto-refresh.
///
/// ```dart
/// import 'package:sadad_flutter/sadad_flutter.dart';
/// import 'package:sadad_qatar/sadad_qatar.dart';
///
/// SadadCheckoutButton(
///   config: SadadConfig(
///     merchantId: '1234567',
///     secretKey:  'your-secret-key',
///     website:    'www.your-domain.com',
///     callbackUrl: 'https://www.your-domain.com/callback',
///   ),
///   orderData: {
///     'order_id': 'ORD-001',
///     'amount':   150.00,
///     'mobile':   '97412345678',
///     'email':    'customer@example.com',
///     'items': [
///       {'order_id': 'ORD-001', 'amount': 150.00, 'quantity': 1},
///     ],
///   },
///   onSuccess: (result) => print('Paid: ${result.transactionNumber}'),
///   onFailure: (error)  => print('Failed: $error'),
/// )
/// ```
library sadad_flutter;

// Widgets
export 'src/widgets/sadad_checkout_button.dart';
export 'src/widgets/sadad_embedded_checkout.dart';
export 'src/widgets/sadad_payment_status.dart';

// Checkout flow manager
export 'src/sadad_checkout.dart';

// WebView wrapper
export 'src/sadad_webview.dart';
