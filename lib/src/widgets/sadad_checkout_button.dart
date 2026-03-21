// Built by Louis Innovations (www.louis-innovations.com)

import 'package:flutter/material.dart';
import 'package:sadad_qatar/sadad_qatar.dart';

import '../sadad_checkout.dart';
import '../sadad_webview.dart';
import 'sadad_embedded_checkout.dart';

/// A "Pay with SADAD" button that drives the full checkout flow.
///
/// - For **v1.1** and **v2.1** (redirect modes) the button opens a full-screen
///   [SadadWebView] that loads the auto-submitting HTML form, follows the
///   SADAD redirect, and intercepts the callback URL.
/// - For **v2.2** (embedded mode) the button opens a [SadadEmbeddedCheckout]
///   inside a modal bottom sheet, keeping the user in-app throughout.
///
/// ```dart
/// SadadCheckoutButton(
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
///   version:   'v1.1',           // 'v1.1', 'v2.1', or 'v2.2'
///   onSuccess: (result) { /* ... */ },
///   onFailure: (error)  { /* ... */ },
/// )
/// ```
class SadadCheckoutButton extends StatefulWidget {
  /// SADAD configuration. See [SadadConfig].
  final SadadConfig config;

  /// Order data map passed to the underlying SDK checkout builder.
  ///
  /// Required keys: `order_id`, `amount`, `mobile`, `email`, `items`.
  final Map<String, dynamic> orderData;

  /// Checkout version: `'v1.1'` (default), `'v2.1'`, or `'v2.2'`.
  ///
  /// - `'v1.1'` — Standard redirect, SHA-256 signature.
  /// - `'v2.1'` — Enhanced redirect, AES-128-CBC checksum.
  /// - `'v2.2'` — Embedded / iFrame checkout (opens as bottom sheet).
  final String version;

  /// Invoked with the parsed [SadadPaymentResult] on a successful payment.
  final void Function(SadadPaymentResult result)? onSuccess;

  /// Invoked with an error description when the payment fails or is
  /// cancelled by the user.
  final void Function(String error)? onFailure;

  // ---- Appearance ----

  /// Label displayed on the button. Defaults to `'Pay with SADAD'`.
  final String label;

  /// Text style for the button label.
  final TextStyle? labelStyle;

  /// Background colour. Defaults to SADAD brand blue `#1A6DB5`.
  final Color? backgroundColor;

  /// Foreground (text + icon) colour. Defaults to white.
  final Color? foregroundColor;

  /// Button border radius. Defaults to 8 dp.
  final BorderRadius? borderRadius;

  /// Minimum button size. Defaults to `Size(double.infinity, 52)`.
  final Size? minimumSize;

  /// Padding inside the button. Defaults to symmetric 16 dp horizontal.
  final EdgeInsetsGeometry? padding;

  /// Custom leading widget. When `null` a small SADAD logo placeholder icon
  /// is shown.
  final Widget? leading;

  /// Whether the button is currently enabled. Defaults to `true`.
  final bool enabled;

  const SadadCheckoutButton({
    super.key,
    required this.config,
    required this.orderData,
    this.version = 'v1.1',
    this.onSuccess,
    this.onFailure,
    this.label = 'Pay with SADAD',
    this.labelStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.minimumSize,
    this.padding,
    this.leading,
    this.enabled = true,
  });

  @override
  State<SadadCheckoutButton> createState() => _SadadCheckoutButtonState();
}

class _SadadCheckoutButtonState extends State<SadadCheckoutButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading || !widget.enabled) return;

    setState(() => _isLoading = true);

    try {
      if (widget.version == 'v2.2') {
        await _openEmbeddedCheckout();
      } else {
        await _openRedirectCheckout();
      }
    } catch (e) {
      widget.onFailure?.call(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Opens the v2.2 embedded checkout as a modal bottom sheet.
  Future<void> _openEmbeddedCheckout() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          height: screenHeight * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SadadEmbeddedCheckout(
                  config: widget.config,
                  orderData: widget.orderData,
                  showCloseButton: false,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  onSuccess: (result) {
                    Navigator.of(context).pop();
                    widget.onSuccess?.call(result);
                  },
                  onFailure: (error) {
                    Navigator.of(context).pop();
                    widget.onFailure?.call(error);
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens a full-screen WebView for v1.1 and v2.1 redirect checkouts.
  Future<void> _openRedirectCheckout() async {
    if (!mounted) return;

    final manager = SadadCheckoutManager(
      config: widget.config,
      version: widget.version,
    );

    String checkoutHtml;
    try {
      checkoutHtml = manager.buildCheckoutHtml(widget.orderData);
    } catch (e) {
      widget.onFailure?.call('Failed to build checkout: $e');
      return;
    }

    final result = await Navigator.of(context).push<SadadPaymentResult>(
      MaterialPageRoute<SadadPaymentResult>(
        builder: (context) => _SadadRedirectPage(
          checkoutHtml: checkoutHtml,
          callbackUrl: widget.config.callbackUrl,
          checkoutManager: manager,
        ),
      ),
    );

    if (result != null) {
      if (result.isSuccess) {
        widget.onSuccess?.call(result);
      } else {
        widget.onFailure?.call(
          result.responseMessage.isNotEmpty
              ? result.responseMessage
              : 'Payment was not completed (code: ${result.responseCode}).',
        );
      }
    } else {
      // User navigated back without completing payment.
      widget.onFailure?.call('Payment was cancelled by the user.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? const Color(0xFF1A6DB5);
    final fgColor = widget.foregroundColor ?? Colors.white;
    final radius = widget.borderRadius ?? BorderRadius.circular(8);
    final minSize = widget.minimumSize ?? const Size(double.infinity, 52);
    final pad = widget.padding ?? const EdgeInsets.symmetric(horizontal: 16);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      minimumSize: minSize,
      padding: pad,
      shape: RoundedRectangleBorder(borderRadius: radius),
      elevation: 2,
      disabledBackgroundColor: bgColor.withOpacity(0.5),
      disabledForegroundColor: fgColor.withOpacity(0.5),
    );

    Widget child;

    if (_isLoading) {
      child = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else {
      final leading = widget.leading ??
          Icon(Icons.payment, color: fgColor, size: 20);

      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: widget.labelStyle ??
                TextStyle(
                  color: fgColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: (widget.enabled && !_isLoading) ? _handleTap : null,
      style: buttonStyle,
      child: child,
    );
  }
}

/// Full-screen page wrapping a [SadadWebView] for redirect checkout modes.
class _SadadRedirectPage extends StatelessWidget {
  final String checkoutHtml;
  final String? callbackUrl;
  final SadadCheckoutManager checkoutManager;

  const _SadadRedirectPage({
    required this.checkoutHtml,
    required this.callbackUrl,
    required this.checkoutManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SADAD Payment'),
        backgroundColor: const Color(0xFF1A6DB5),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel payment',
          onPressed: () => Navigator.of(context).pop<SadadPaymentResult>(null),
        ),
      ),
      body: SadadWebView(
        initialHtml: checkoutHtml,
        callbackUrl: callbackUrl,
        onCallbackDetected: (url) {
          final result = checkoutManager.parseCallbackUrl(url);
          Navigator.of(context).pop<SadadPaymentResult>(result);
        },
      ),
    );
  }
}
