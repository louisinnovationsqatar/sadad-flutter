// Built by Louis Innovations (www.louis-innovations.com)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sadad_qatar/sadad_qatar.dart';

/// Displays the current status of a SADAD transaction with optional
/// auto-refresh.
///
/// Calls [onFetchStatus] periodically while [autoRefresh] is `true` and the
/// transaction is still in a pending/processing state.
///
/// ```dart
/// SadadPaymentStatus(
///   transactionNumber: 'TXN-123456789',
///   config: sadadConfig,
///   onSuccess: (result) { /* fulfil order */ },
///   autoRefresh: true,
///   refreshIntervalSeconds: 5,
/// )
/// ```
class SadadPaymentStatus extends StatefulWidget {
  /// The SADAD transaction reference number to query.
  final String transactionNumber;

  /// SADAD configuration used to instantiate [SadadClient].
  final SadadConfig config;

  /// Invoked each time the status is fetched from the API.
  ///
  /// Receives the raw `Map<String, dynamic>` returned by
  /// [SadadClient.getTransaction].
  final void Function(Map<String, dynamic> data)? onStatusFetched;

  /// Invoked when [transactionNumber] resolves to a successful transaction.
  ///
  /// Once invoked, auto-refresh stops automatically.
  final void Function(Map<String, dynamic> data)? onSuccess;

  /// Invoked when a fetch error occurs.
  final void Function(String error)? onError;

  /// Whether to poll [SadadClient.getTransaction] repeatedly.
  final bool autoRefresh;

  /// Polling interval in seconds. Defaults to `5`.
  final int refreshIntervalSeconds;

  /// Maximum number of auto-refresh attempts. `0` means unlimited.
  /// Defaults to `60` (5 minutes at 5-second intervals).
  final int maxRefreshAttempts;

  const SadadPaymentStatus({
    super.key,
    required this.transactionNumber,
    required this.config,
    this.onStatusFetched,
    this.onSuccess,
    this.onError,
    this.autoRefresh = false,
    this.refreshIntervalSeconds = 5,
    this.maxRefreshAttempts = 60,
  });

  @override
  State<SadadPaymentStatus> createState() => _SadadPaymentStatusState();
}

class _SadadPaymentStatusState extends State<SadadPaymentStatus> {
  late final SadadClient _client;
  Timer? _timer;
  int _attempts = 0;

  _TransactionStatus _status = _TransactionStatus.loading;
  String _statusMessage = 'Fetching payment status...';
  Map<String, dynamic>? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _client = SadadClient(widget.config);
    _fetchStatus();

    if (widget.autoRefresh) {
      _timer = Timer.periodic(
        Duration(seconds: widget.refreshIntervalSeconds),
        (_) => _fetchStatus(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    if (!mounted) return;

    _attempts++;
    final maxAttempts = widget.maxRefreshAttempts;
    if (maxAttempts > 0 && _attempts > maxAttempts) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _status = _TransactionStatus.timeout;
          _statusMessage = 'Status check timed out. Please refresh manually.';
        });
      }
      return;
    }

    try {
      final result = await _client.getTransaction(widget.transactionNumber);
      if (!mounted) return;

      widget.onStatusFetched?.call(result);

      if (result['success'] == true) {
        final transaction = result['transaction'] as Map<String, dynamic>?;
        final txnStatus = _parseTransactionStatus(transaction);

        setState(() {
          _data = transaction;
          _status = txnStatus;
          _statusMessage = _statusLabel(txnStatus, transaction);
        });

        if (txnStatus == _TransactionStatus.success) {
          _timer?.cancel();
          widget.onSuccess?.call(result);
        }
      } else {
        setState(() {
          _status = _TransactionStatus.error;
          _errorMessage = result['error']?.toString() ?? 'Unknown error.';
          _statusMessage = _errorMessage!;
        });
        widget.onError?.call(_errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _status = _TransactionStatus.error;
        _errorMessage = msg;
        _statusMessage = msg;
      });
      widget.onError?.call(msg);
    }
  }

  _TransactionStatus _parseTransactionStatus(
    Map<String, dynamic>? transaction,
  ) {
    if (transaction == null) return _TransactionStatus.unknown;

    // SADAD API uses numeric transaction status codes.
    // Status 3 = Success (as per SADAD documentation).
    final rawStatus = transaction['transactionStatus'] ??
        transaction['status'] ??
        transaction['STATUS'];

    final statusCode = int.tryParse(rawStatus?.toString() ?? '') ?? -1;

    return switch (statusCode) {
      3 => _TransactionStatus.success,
      1 => _TransactionStatus.pending,
      2 => _TransactionStatus.pending,
      4 => _TransactionStatus.failed,
      5 => _TransactionStatus.refunded,
      _ => _TransactionStatus.unknown,
    };
  }

  String _statusLabel(
    _TransactionStatus status,
    Map<String, dynamic>? transaction,
  ) {
    return switch (status) {
      _TransactionStatus.loading => 'Fetching payment status...',
      _TransactionStatus.pending => 'Payment is being processed...',
      _TransactionStatus.success => 'Payment successful.',
      _TransactionStatus.failed => 'Payment failed.',
      _TransactionStatus.refunded => 'Transaction refunded.',
      _TransactionStatus.timeout => 'Status check timed out.',
      _TransactionStatus.error => _errorMessage ?? 'An error occurred.',
      _TransactionStatus.unknown => 'Payment status unknown.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusIcon(status: _status),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _statusColor(_status),
                  ),
            ),
            if (_data != null) ...[
              const SizedBox(height: 12),
              _TransactionDetails(data: _data!),
            ],
            if (_status == _TransactionStatus.loading ||
                (_status == _TransactionStatus.pending && widget.autoRefresh))
              ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A6DB5)),
                  backgroundColor: Color(0xFFE0EAF5),
                ),
              ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _attempts = 0;
                    setState(() {
                      _status = _TransactionStatus.loading;
                      _statusMessage = 'Fetching payment status...';
                    });
                    _fetchStatus();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(_TransactionStatus status) {
    return switch (status) {
      _TransactionStatus.success => const Color(0xFF2E7D32),
      _TransactionStatus.failed || _TransactionStatus.error => Colors.red,
      _TransactionStatus.pending || _TransactionStatus.loading =>
        const Color(0xFF1A6DB5),
      _ => Colors.grey,
    };
  }
}

// ---------------------------------------------------------------------------
// Supporting enumerations and sub-widgets
// ---------------------------------------------------------------------------

enum _TransactionStatus {
  loading,
  pending,
  success,
  failed,
  refunded,
  error,
  timeout,
  unknown,
}

class _StatusIcon extends StatelessWidget {
  final _TransactionStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _TransactionStatus.loading => const SizedBox(
          height: 48,
          width: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A6DB5)),
          ),
        ),
      _TransactionStatus.success => const Icon(
          Icons.check_circle_outline,
          size: 48,
          color: Color(0xFF2E7D32),
        ),
      _TransactionStatus.failed || _TransactionStatus.error => const Icon(
          Icons.cancel_outlined,
          size: 48,
          color: Colors.red,
        ),
      _TransactionStatus.pending => const Icon(
          Icons.hourglass_top_outlined,
          size: 48,
          color: Color(0xFF1A6DB5),
        ),
      _TransactionStatus.refunded => const Icon(
          Icons.replay_outlined,
          size: 48,
          color: Colors.orange,
        ),
      _TransactionStatus.timeout => const Icon(
          Icons.timer_off_outlined,
          size: 48,
          color: Colors.grey,
        ),
      _ => const Icon(Icons.help_outline, size: 48, color: Colors.grey),
    };
  }
}

class _TransactionDetails extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TransactionDetails({required this.data});

  @override
  Widget build(BuildContext context) {
    final txnNo = data['transactionNo'] ??
        data['transactionNumber'] ??
        data['TXNID'] ??
        '';
    final orderId = data['orderId'] ?? data['ORDERID'] ?? '';
    final amount = data['amount']?.toString() ?? data['TXNAMOUNT'] ?? '';

    final rows = <_DetailRow>[];

    if (txnNo.toString().isNotEmpty) {
      rows.add(_DetailRow(label: 'Transaction', value: txnNo.toString()));
    }
    if (orderId.toString().isNotEmpty) {
      rows.add(_DetailRow(label: 'Order', value: orderId.toString()));
    }
    if (amount.isNotEmpty) {
      rows.add(_DetailRow(label: 'Amount', value: 'QAR $amount'));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    r.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
}
