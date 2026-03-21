# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-21

### Added
- Initial release
- `SadadCheckoutButton` — "Pay with SADAD" StatefulWidget supporting v1.1, v2.1, and v2.2 checkout modes
  - Opens full-screen WebView for redirect modes (v1.1, v2.1)
  - Opens modal bottom sheet with embedded checkout for v2.2
  - Customisable appearance: label, colours, border radius, minimum size, padding, leading widget
  - Built-in loading indicator during checkout initialisation
- `SadadEmbeddedCheckout` — WebView widget for v2.2 embedded (secure) checkout
  - Loads `https://secure.sadadqa.com/webpurchasepage` in WebView
  - Intercepts callback URL navigation to extract payment result
  - Optional close button and border radius
  - Retry support on checkout build error
- `SadadPaymentStatus` — Transaction status display widget with auto-refresh
  - Polls `SadadClient.getTransaction` at a configurable interval
  - Renders status icon, message, and transaction details
  - Configurable max refresh attempts (default 60)
  - Manual refresh button always available
- `SadadCheckoutManager` — Checkout flow manager
  - Wraps `SadadClient.checkout` for all three versions
  - `buildCheckoutHtml` — generates auto-submitting HTML redirect page
  - `isCallbackUrl` — detects SADAD callback URL navigation
  - `parseCallbackUrl` — extracts `SadadPaymentResult` from callback URL query parameters
- `SadadPaymentResult` — Payment result model
  - Constructors: `fromCallbackResult`, `fromQueryParameters`
  - Fields: `isSuccess`, `orderNumber`, `transactionNumber`, `amount`, `responseCode`, `responseMessage`, `status`
- `SadadWebView` — Configured WebView wrapper
  - JavaScript enabled, DOM storage enabled
  - Intercepts callback URL navigation
  - Shows loading overlay while first page loads
  - Supports both `initialUrl` and `initialHtml`
- Complete example app (`example/`) demonstrating all three checkout modes
- MIT License
- `analysis_options.yaml` with flutter_lints rules
