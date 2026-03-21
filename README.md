# sadad_flutter

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Flutter: 3.10+](https://img.shields.io/badge/Flutter-3.10%2B-blue.svg)](https://flutter.dev/)
[![Dart: 3.0+](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev/)
[![pub.dev](https://img.shields.io/pub/v/sadad_flutter.svg)](https://pub.dev/packages/sadad_flutter)

Flutter widget library for the [SADAD Payment Gateway](https://www.sadad.qa/) — Qatar's leading payment platform.

Wraps the [`sadad_qatar`](https://pub.dev/packages/sadad_qatar) Dart SDK with ready-to-use Flutter widgets for payment checkout, embedded WebView, and transaction status display.

Built by [Louis Innovations](https://www.louis-innovations.com)

---

## Features

- `SadadCheckoutButton` — a "Pay with SADAD" button that handles the complete checkout flow
- `SadadEmbeddedCheckout` — a WebView widget for the v2.2 embedded (secure) checkout
- `SadadPaymentStatus` — a transaction status widget with auto-refresh
- `SadadCheckoutManager` — programmatic checkout flow manager
- `SadadWebView` — configured WebView wrapper with callback URL interception
- Supports all three SADAD checkout modes: v1.1, v2.1, v2.2
- Full-screen WebView for redirect modes (v1.1, v2.1)
- Modal bottom sheet embedded checkout for v2.2
- Callback URL interception on mobile and web
- Customisable button appearance

---

## Requirements

- Flutter `>=3.10.0`
- Dart SDK `^3.0.0`
- `sadad_qatar: ^1.0.0`
- `webview_flutter: ^4.0.0`

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  sadad_flutter: ^1.0.0
  sadad_qatar: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Platform Setup

### Android

1. Set the minimum SDK version to 19 in `android/app/build.gradle`:

   ```gradle
   defaultConfig {
       minSdkVersion 19
   }
   ```

2. Add an intent-filter for deep link callbacks in `android/app/src/main/AndroidManifest.xml` inside the `<activity>` tag:

   ```xml
   <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <!-- Replace with your actual callback scheme and host -->
       <data
           android:scheme="https"
           android:host="www.your-domain.com"
           android:pathPrefix="/payment/callback" />
   </intent-filter>
   ```

3. Enable WebView DOM storage (required for SADAD embedded checkout). Add to `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <application
       android:usesCleartextTraffic="true">
   ```

   > Note: In production, SADAD uses HTTPS only. `usesCleartextTraffic` is only needed if you have a test environment using HTTP.

### iOS

1. Set the minimum deployment target to iOS 11 in `ios/Podfile`:

   ```ruby
   platform :ios, '11.0'
   ```

2. Add a URL scheme for deep link callbacks in `ios/Runner/Info.plist`:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLName</key>
           <string>com.your.app.sadad</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>sadad-your-app</string>
           </array>
       </dict>
   </array>
   ```

3. Allow arbitrary loads in test environments (remove for production):

   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   ```

### Web

For web builds, `webview_flutter` uses `HtmlElementView` with an `<iframe>` internally. No additional setup is needed for embedded checkout (v2.2).

For redirect modes (v1.1 and v2.1), the checkout page opens in an iframe. The callback URL is detected when the iframe navigates to your callback URL.

> **Important for web:** Ensure your web server sets appropriate CORS headers on the callback URL so the iframe can detect navigation. For same-origin callback URLs this is not required.

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:sadad_flutter/sadad_flutter.dart';
import 'package:sadad_qatar/sadad_qatar.dart';

// 1. Configure SADAD credentials
final config = SadadConfig(
  merchantId:  '1234567',
  secretKey:   'your-secret-key',
  website:     'www.your-domain.com',
  environment: 'test',                    // 'test' or 'live'
  language:    'eng',                     // 'eng' or 'arb'
  callbackUrl: 'https://www.your-domain.com/payment/callback',
);

// 2. Define order data
final orderData = {
  'order_id': 'ORD-001',
  'amount':   150.00,
  'mobile':   '97412345678',
  'email':    'customer@example.com',
  'items': [
    {'order_id': 'ORD-001', 'amount': 150.00, 'quantity': 1},
  ],
};

// 3. Add SadadCheckoutButton to your widget tree
SadadCheckoutButton(
  config:    config,
  orderData: orderData,
  version:   'v1.1',
  onSuccess: (result) {
    print('Payment successful! Transaction: ${result.transactionNumber}');
  },
  onFailure: (error) {
    print('Payment failed: $error');
  },
)
```

---

## Widgets

### SadadCheckoutButton

A "Pay with SADAD" button that handles the complete checkout flow.

```dart
SadadCheckoutButton(
  config:    sadadConfig,
  orderData: orderData,
  version:   'v1.1',           // 'v1.1', 'v2.1', or 'v2.2'

  // Callbacks
  onSuccess: (SadadPaymentResult result) { /* ... */ },
  onFailure: (String error)              { /* ... */ },

  // Appearance (all optional)
  label:           'Pay with SADAD',
  labelStyle:      TextStyle(fontSize: 16),
  backgroundColor: Color(0xFF1A6DB5),    // SADAD brand blue
  foregroundColor: Colors.white,
  borderRadius:    BorderRadius.circular(8),
  minimumSize:     Size(double.infinity, 52),
  padding:         EdgeInsets.symmetric(horizontal: 16),
  leading:         Icon(Icons.payment), // custom leading widget
  enabled:         true,
)
```

**Checkout mode behaviour:**

| Version | Behaviour |
|---------|-----------|
| `v1.1`  | Opens a full-screen `Scaffold` with a `SadadWebView`. Loads an auto-submitting HTML form that redirects the customer to `sadadqa.com/webpurchase`. |
| `v2.1`  | Same as v1.1, but uses the AES-encrypted checksum flow. |
| `v2.2`  | Opens a modal bottom sheet containing a `SadadEmbeddedCheckout` pointing to `secure.sadadqa.com/webpurchasepage`. |

### SadadEmbeddedCheckout

Embeds the SADAD v2.2 checkout directly in your widget tree.

```dart
SadadEmbeddedCheckout(
  config:    sadadConfig,   // callbackUrl is required
  orderData: orderData,

  onSuccess: (result) { /* ... */ },
  onFailure: (error)  { /* ... */ },
  onCancel:  ()       { Navigator.pop(context); },

  showCloseButton:      true,
  showLoadingIndicator: true,
  borderRadius:         BorderRadius.circular(12),
)
```

Typically embedded inside a `Dialog`, `BottomSheet`, or `Scaffold` body.

### SadadPaymentStatus

Displays the current status of a SADAD transaction with optional auto-refresh.

```dart
SadadPaymentStatus(
  transactionNumber:      'TXN-123456789',
  config:                 sadadConfig,

  autoRefresh:            true,
  refreshIntervalSeconds: 5,
  maxRefreshAttempts:     60,   // 5 minutes

  onStatusFetched: (data)  { /* raw API response */ },
  onSuccess:       (data)  { /* transaction confirmed */ },
  onError:         (error) { /* fetch error */ },
)
```

### SadadWebView

A low-level configured WebView for custom payment flows.

```dart
SadadWebView(
  initialHtml: htmlFormString,       // OR
  initialUrl:  'https://...',

  callbackUrl:         'https://www.your-domain.com/callback',
  onCallbackDetected:  (url) { /* parse result */ },
  onPageStarted:       (url) { /* loading */ },
  onPageFinished:      (url) { /* loaded */ },
  onWebResourceError:  (err) { /* error */ },
  showLoadingIndicator: true,
)
```

---

## Checkout Modes

### v1.1 — Standard Web Redirect

The customer is redirected to the SADAD payment page via an HTML form POST. A SHA-256 signature is generated from the order parameters.

```dart
SadadCheckoutButton(
  config:    config,
  orderData: orderData,
  version:   'v1.1',
  onSuccess: (result) { /* ... */ },
  onFailure: (error)  { /* ... */ },
)
```

### v2.1 — Enhanced Web Redirect

Same redirect flow as v1.1 but with an AES-128-CBC encrypted checksum for improved security.

```dart
SadadCheckoutButton(
  config:    config,
  orderData: orderData,
  version:   'v2.1',
  onSuccess: (result) { /* ... */ },
  onFailure: (error)  { /* ... */ },
)
```

### v2.2 — Embedded / iFrame Checkout

The payment form is rendered inside your app using a WebView. The customer never leaves your app.

```dart
SadadCheckoutButton(
  config:    config,
  orderData: orderData,
  version:   'v2.2',
  onSuccess: (result) { /* ... */ },
  onFailure: (error)  { /* ... */ },
)
```

---

## SadadPaymentResult

All `onSuccess` callbacks receive a `SadadPaymentResult`:

| Property             | Type      | Description                                      |
|----------------------|-----------|--------------------------------------------------|
| `isSuccess`          | `bool`    | `true` when `RESPCODE == '1'`                    |
| `orderNumber`        | `String`  | Your original order ID                           |
| `transactionNumber`  | `String`  | SADAD gateway transaction reference              |
| `amount`             | `double`  | Transaction amount in QAR                        |
| `responseCode`       | `String`  | SADAD response code (e.g. `'1'`)                 |
| `responseMessage`    | `String`  | Human-readable response message                  |
| `status`             | `String`  | Raw transaction status string                    |

---

## Programmatic Usage — SadadCheckoutManager

Use `SadadCheckoutManager` directly when you need more control over the checkout flow:

```dart
final manager = SadadCheckoutManager(
  config:  sadadConfig,
  version: 'v1.1',
);

// Build the checkout — returns CheckoutResult from sadad_qatar SDK
final checkoutResult = manager.buildCheckout(orderData);

// Or build a complete HTML page with auto-submitting form
final html = manager.buildCheckoutHtml(orderData);

// Load html into your own WebView, then detect the callback:
if (manager.isCallbackUrl(navigationUrl)) {
  final result = manager.parseCallbackUrl(navigationUrl);
  if (result != null && result.isSuccess) {
    // Handle success
  }
}
```

---

## Error Handling

The `onFailure` callback receives a human-readable error string:

```dart
SadadCheckoutButton(
  // ...
  onFailure: (String error) {
    // Examples:
    // 'Payment was cancelled by the user.'
    // 'Failed to build checkout: Merchant ID must be exactly 7 digits.'
    // 'Payment was not completed (code: 2).'
    // 'Unable to parse the SADAD callback response.'
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(error),
      ),
    );
  },
)
```

---

## Order Data Structure

All three checkout versions accept the same order data map:

```dart
final orderData = {
  'order_id':     'ORD-001',              // Unique merchant order ID
  'amount':       150.00,                 // Total amount in QAR
  'mobile':       '97412345678',          // Customer mobile (digits only)
  'email':        'customer@example.com',
  'callback_url': 'https://...',          // Optional: overrides config callbackUrl
  'items': [
    {
      'order_id': 'ORD-001',
      'amount':   150.00,
      'quantity': 1,
    },
  ],
};
```

---

## Example App

A complete demo app is included in the [`example/`](example/) directory. Run it with:

```bash
cd example
flutter pub get
flutter run
```

The example app demonstrates all three checkout modes and the payment status widget.

---

## Testing

```bash
flutter test
```

---

## Troubleshooting

**"Merchant ID must be exactly 7 digits"**
Ensure your merchant ID is exactly 7 numeric digits (e.g. `7015085`). Do not include spaces or dashes.

**WebView does not load on Android**
Set `minSdkVersion 19` in `android/app/build.gradle`.

**Callback URL never intercepted**
Verify that `SadadConfig.callbackUrl` exactly matches the URL SADAD redirects to after payment. The comparison is case-insensitive on scheme and host but path must match with `startsWith`.

**iOS: WebView shows blank page**
Add `NSAllowsArbitraryLoads` (for test environments only) or ensure SADAD test endpoints are accessible from your network.

**Web: iframe blocked by CORS**
For web builds, the callback URL must be on the same origin as your Flutter web app, or the SADAD gateway must set `Access-Control-Allow-Origin` on the callback response. For cross-origin setups, use server-side callback handling with webhooks instead.

**"No access token in response"**
Check that `merchantId`, `secretKey`, and `website` in `SadadConfig` exactly match the values registered at [panel.sadad.qa](https://panel.sadad.qa). Also verify `environment: 'test'` while testing.

---

## Bug Reports

Please open an issue on [GitHub Issues](https://github.com/louis-innovations/sadad-flutter/issues) or email [info@louis-innovations.com](mailto:info@louis-innovations.com).

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

---

Built by [Louis Innovations](https://www.louis-innovations.com)
