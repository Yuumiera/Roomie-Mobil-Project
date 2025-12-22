import 'package:flutter/material.dart';

import '../services/alert_subscription_service.dart';

class AlertSubscriptionDialog extends StatefulWidget {
  const AlertSubscriptionDialog({
    super.key,
    required this.criteria,
    required this.summary,
  });

  final Map<String, dynamic> criteria;
  final Map<String, String> summary;

  @override
  State<AlertSubscriptionDialog> createState() => _AlertSubscriptionDialogState();
}

class _AlertSubscriptionDialogState extends State<AlertSubscriptionDialog> {
  bool _isProcessing = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      await AlertSubscriptionService().createSubscription(criteria: widget.criteria);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bildirim Oluştur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aşağıdaki kriterlere uygun yeni bir ilan eklendiğinde size bildirim gönderilecektir.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Seçilen Kriterler:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.summary.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(entry.value),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _submit,
          icon: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.notifications_active),
          label: Text(_isProcessing ? 'İşleniyor...' : 'Bildirimi Oluştur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ECDC4),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

