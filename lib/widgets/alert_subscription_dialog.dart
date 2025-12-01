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
  final List<String> _cards = [
    'Visa •••• 4242',
    'Mastercard •••• 5500',
    'Troy •••• 0012',
  ];
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _newCardNameController = TextEditingController();
  final TextEditingController _newCardDigitsController = TextEditingController();

  bool _accepted = true;
  bool _isProcessing = false;
  bool _cardVerified = false;
  String? _selectedCard;
  String? _error;
  String? _verificationMessage;
  bool _addingNewCard = false;

  @override
  void initState() {
    super.initState();
    _selectedCard = _cards.first;
  }

  @override
  void dispose() {
    _cvvController.dispose();
    _newCardDigitsController.dispose();
    _newCardNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      await AlertSubscriptionService().createSubscription(criteria: widget.criteria);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  void _verifyCard() {
    setState(() {
      _verificationMessage = null;
      _error = null;
    });
    if (_selectedCard == null || _cvvController.text.trim().length != 3) {
      setState(() {
        _verificationMessage = 'Lütfen kart seçin ve 3 haneli CVV girin.';
        _cardVerified = false;
      });
      return;
    }
    setState(() {
      _verificationMessage = '$_selectedCard doğrulandı.';
      _cardVerified = true;
    });
  }

  void _saveNewCard() {
    final name = _newCardNameController.text.trim();
    final digits = _newCardDigitsController.text.trim();
    if (name.isEmpty || digits.length != 4) {
      setState(() {
        _verificationMessage = 'Kart adı ve 4 haneli son rakam zorunludur.';
        _cardVerified = false;
      });
      return;
    }
    final formatted = '$name •••• $digits';
    setState(() {
      _cards.add(formatted);
      _selectedCard = formatted;
      _addingNewCard = false;
      _newCardDigitsController.clear();
      _newCardNameController.clear();
      _verificationMessage = 'Yeni kart eklendi. Lütfen CVV girip doğrulayın.';
      _cardVerified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bu arama için bildirim al'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seçilen filtreler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.summary.entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(entry.key),
                trailing: Text(entry.value),
              ),
            ),
            const Divider(),
            Text(
              'Bu kriterler için aylık \$${AlertSubscriptionService.subscriptionCostUsd.toStringAsFixed(0)} karşılığında bildirim alabilirsiniz. '
              'Ödeme işlemi mock olarak gerçekleşir.',
            ),
            const SizedBox(height: 12),
            Text(
              'Ödeme yöntemi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCard,
              items: _cards.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() {
                _selectedCard = value;
                _cardVerified = false;
              }),
              decoration: const InputDecoration(labelText: 'Kart seç'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _addingNewCard = !_addingNewCard;
                  _verificationMessage = null;
                  _cardVerified = false;
                }),
                icon: Icon(_addingNewCard ? Icons.close : Icons.add_card),
                label: Text(_addingNewCard ? 'Kart eklemeyi iptal et' : 'Yeni kart ekle'),
              ),
            ),
            if (_addingNewCard) ...[
              TextFormField(
                controller: _newCardNameController,
                decoration: const InputDecoration(labelText: 'Kart adı (örn. Visa Platinum)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newCardDigitsController,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Son 4 hane', counterText: ''),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saveNewCard,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Kartı kaydet'),
                ),
              ),
              const Divider(),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _cvvController,
              maxLength: 3,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'CVV', counterText: ''),
              onChanged: (_) => setState(() => _cardVerified = false),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _verifyCard,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Kartı doğrula'),
              ),
            ),
            if (_verificationMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _verificationMessage!,
                  style: TextStyle(color: _cardVerified ? Colors.green : Colors.red),
                ),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v ?? false),
              title: const Text('Ödeme ve kullanım koşullarını onaylıyorum.'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
          onPressed: (!_accepted || !_cardVerified || _isProcessing) ? null : _submit,
          icon: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.notifications_active),
          label: Text(_isProcessing ? 'İşleniyor...' : '10\$ öde ve başlat'),
        ),
      ],
    );
  }
}

