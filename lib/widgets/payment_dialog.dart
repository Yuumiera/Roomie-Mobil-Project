import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({
    super.key,
    required this.amount,
    required this.title,
    required this.description,
  });

  final double amount;
  final String title;
  final String description;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
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
    setState(() => _isProcessing = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop(true);
  }

  void _verifyCard() {
    setState(() => _verificationMessage = null);
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
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            const SizedBox(height: 12),
            Text(
              'Ödenecek Tutar: \$${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8B4513)),
            ),
            const SizedBox(height: 16),
            Text(
              'Ödeme Yöntemi',
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
              decoration: const InputDecoration(labelText: 'Kart Seç'),
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
                label: Text(_addingNewCard ? 'İptal' : 'Yeni Kart Ekle'),
              ),
            ),
            if (_addingNewCard) ...[
              TextFormField(
                controller: _newCardNameController,
                decoration: const InputDecoration(labelText: 'Kart Adı'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newCardDigitsController,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Son 4 Hane', counterText: ''),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _saveNewCard,
                  child: const Text('Kaydet'),
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
                label: const Text('Kartı Doğrula'),
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
              title: const Text('Ödeme koşullarını onaylıyorum.'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: (!_accepted || !_cardVerified || _isProcessing) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Ödemeyi Tamamla'),
        ),
      ],
    );
  }
}
