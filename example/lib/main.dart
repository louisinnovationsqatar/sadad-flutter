// Built by Louis Innovations (www.louis-innovations.com)

import 'package:flutter/material.dart';
import 'package:sadad_flutter/sadad_flutter.dart';
import 'package:sadad_qatar/sadad_qatar.dart';

void main() {
  runApp(const SadadExampleApp());
}

/// Example application demonstrating [SadadCheckoutButton] usage.
///
/// Replace the placeholder credentials and order data with real values
/// obtained from your SADAD merchant account at https://panel.sadad.qa.
class SadadExampleApp extends StatelessWidget {
  const SadadExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SADAD Flutter Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6DB5),
        ),
        useMaterial3: true,
      ),
      home: const CheckoutDemoPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo page
// ---------------------------------------------------------------------------

class CheckoutDemoPage extends StatefulWidget {
  const CheckoutDemoPage({super.key});

  @override
  State<CheckoutDemoPage> createState() => _CheckoutDemoPageState();
}

class _CheckoutDemoPageState extends State<CheckoutDemoPage> {
  // ---- SADAD credentials (replace with real values) ----
  static final SadadConfig _config = SadadConfig(
    merchantId: '1234567',
    secretKey: 'your-secret-key',
    website: 'www.your-domain.com',
    environment: 'test',
    language: 'eng',
    callbackUrl: 'https://www.your-domain.com/payment/callback',
  );

  // ---- Order data ----
  static const Map<String, dynamic> _orderData = {
    'order_id': 'ORD-001',
    'amount': 150.00,
    'mobile': '97412345678',
    'email': 'customer@example.com',
    'items': [
      {'order_id': 'ORD-001', 'amount': 150.00, 'quantity': 1},
    ],
  };

  String _selectedVersion = 'v1.1';
  String? _lastTransactionNumber;
  String _resultMessage = 'Awaiting payment...';
  bool _isSuccess = false;

  void _handleSuccess(SadadPaymentResult result) {
    setState(() {
      _isSuccess = true;
      _lastTransactionNumber = result.transactionNumber;
      _resultMessage =
          'Payment successful!\n'
          'Transaction: ${result.transactionNumber}\n'
          'Order: ${result.orderNumber}\n'
          'Amount: QAR ${result.amount.toStringAsFixed(2)}';
    });
    _showSnackBar('Payment successful.', isError: false);
  }

  void _handleFailure(String error) {
    setState(() {
      _isSuccess = false;
      _resultMessage = 'Payment failed:\n$error';
    });
    _showSnackBar(error, isError: true);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SADAD Payment Demo'),
        backgroundColor: const Color(0xFF1A6DB5),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary card
              _OrderSummaryCard(orderData: _orderData),

              const SizedBox(height: 24),

              // Version selector
              Text(
                'Checkout Version',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _VersionSelector(
                selected: _selectedVersion,
                onChanged: (v) => setState(() => _selectedVersion = v),
              ),

              const SizedBox(height: 28),

              // Checkout button
              SadadCheckoutButton(
                config: _config,
                orderData: _orderData,
                version: _selectedVersion,
                onSuccess: _handleSuccess,
                onFailure: _handleFailure,
              ),

              const SizedBox(height: 28),

              // Result area
              _ResultCard(
                message: _resultMessage,
                isSuccess: _isSuccess,
              ),

              // Payment status widget (shown after a transaction)
              if (_lastTransactionNumber != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Transaction Status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SadadPaymentStatus(
                  transactionNumber: _lastTransactionNumber!,
                  config: _config,
                  autoRefresh: true,
                  refreshIntervalSeconds: 5,
                  onSuccess: (data) {
                    _showSnackBar(
                      'Transaction confirmed as successful.',
                      isError: false,
                    );
                  },
                  onError: (error) {
                    _showSnackBar(error, isError: true);
                  },
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _OrderSummaryCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const _OrderSummaryCard({required this.orderData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _Row(label: 'Order ID', value: orderData['order_id'].toString()),
            _Row(
              label: 'Amount',
              value:
                  'QAR ${(orderData['amount'] as num).toStringAsFixed(2)}',
            ),
            _Row(label: 'Email', value: orderData['email'].toString()),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _VersionSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _VersionSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const versions = [
      ('v1.1', 'v1.1 — Standard redirect (SHA-256)'),
      ('v2.1', 'v2.1 — Enhanced redirect (AES)'),
      ('v2.2', 'v2.2 — Embedded checkout'),
    ];

    return Column(
      children: versions
          .map(
            (v) => RadioListTile<String>(
              title: Text(v.$2, style: const TextStyle(fontSize: 14)),
              value: v.$1,
              groupValue: selected,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF1A6DB5),
            ),
          )
          .toList(),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const _ResultCard({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isSuccess ? const Color(0xFF2E7D32) : Colors.grey.shade700,
          fontSize: 14,
        ),
      ),
    );
  }
}
