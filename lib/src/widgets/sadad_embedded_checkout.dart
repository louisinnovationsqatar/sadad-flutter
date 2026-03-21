// Built by Louis Innovations (www.louis-innovations.com)

import 'package:flutter/material.dart';
import 'package:sadad_qatar/sadad_qatar.dart';

import '../sadad_checkout.dart';
import '../sadad_webview.dart';

/// A WebView widget for the SADAD v2.2 embedded (secure) checkout.
///
/// Loads `https://secure.sadadqa.com/webpurchasepage` in a [SadadWebView],
/// posts the AES-encrypted checkout parameters, and intercepts the SADAD
/// callback URL to extract the payment result.
///
/// Typically embedded inside a [Scaffold] body or a [Dialog]:
///
/// ```dart
/// SadadEmbeddedCheckout(
///   config: SadadConfig(
///     merchantId:  '1234567',
///     secretKey:   'your-secret-key',
///     website:     'www.your-domain.com',
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
///   onSuccess: (result) { /* handle success */ },
///   onFailure: (error)  { /* handle failure */ },
///   onCancel:  ()       { /* handle cancel  */ },
/// )
/// ```
class SadadEmbeddedCheckout extends StatefulWidget {
  /// The SADAD configuration. Must include [SadadConfig.callbackUrl] so the
  /// widget can intercept the post-payment redirect.
  final SadadConfig config;

  /// Order data passed directly to the `sadad_qatar` v2.2 checkout builder.
  ///
  /// Required keys: `order_id`, `amount`, `mobile`, `email`, `items`.
  final Map<String, dynamic> orderData;

  /// Invoked with the parsed [SadadPaymentResult] when payment succeeds
  /// (`RESPCODE == '1'`).
  final void Function(SadadPaymentResult result)? onSuccess;

  /// Invoked with an error message when the payment fails or the callback
  /// returns a non-success response code.
  final void Function(String error)? onFailure;

  /// Invoked when the user taps the close button without completing payment.
  final VoidCallback? onCancel;

  /// Whether to show a close button in the top-right corner.
  final bool showCloseButton;

  /// Whether to show the loading indicator while the payment page loads.
  final bool showLoadingIndicator;

  /// Border radius for the widget. Useful when embedded inside a card or
  /// bottom sheet. Defaults to [BorderRadius.zero].
  final BorderRadius borderRadius;

  const SadadEmbeddedCheckout({
    super.key,
    required this.config,
    required this.orderData,
    this.onSuccess,
    this.onFailure,
    this.onCancel,
    this.showCloseButton = true,
    this.showLoadingIndicator = true,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<SadadEmbeddedCheckout> createState() => _SadadEmbeddedCheckoutState();
}

class _SadadEmbeddedCheckoutState extends State<SadadEmbeddedCheckout> {
  late final SadadCheckoutManager _manager;
  late final String _checkoutHtml;
  String? _buildError;

  @override
  void initState() {
    super.initState();
    _manager = SadadCheckoutManager(config: widget.config, version: 'v2.2');
    _buildCheckoutHtml();
  }

  void _buildCheckoutHtml() {
    try {
      _checkoutHtml = _manager.buildCheckoutHtml(widget.orderData);
    } catch (e) {
      _buildError = e.toString();
    }
  }

  void _handleCallback(String url) {
    final result = _manager.parseCallbackUrl(url);

    if (result == null) {
      widget.onFailure?.call(
        'Unable to parse the SADAD callback response.',
      );
      return;
    }

    if (result.isSuccess) {
      widget.onSuccess?.call(result);
    } else {
      widget.onFailure?.call(
        result.responseMessage.isNotEmpty
            ? result.responseMessage
            : 'Payment was not completed (code: ${result.responseCode}).',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_buildError != null) {
      return _ErrorView(
        message: _buildError!,
        onRetry: () => setState(_buildCheckoutHtml),
      );
    }

    Widget child = SadadWebView(
      initialHtml: _checkoutHtml,
      callbackUrl: widget.config.callbackUrl,
      onCallbackDetected: _handleCallback,
      showLoadingIndicator: widget.showLoadingIndicator,
    );

    if (widget.showCloseButton) {
      child = Stack(
        children: [
          child,
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onCancel,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.borderRadius != BorderRadius.zero) {
      child = ClipRRect(
        borderRadius: widget.borderRadius,
        child: child,
      );
    }

    return child;
  }
}

/// Internal error view shown when checkout form construction fails.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Unable to load checkout',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
