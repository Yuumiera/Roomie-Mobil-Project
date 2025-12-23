import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_dialog.dart';

class UpgradePremiumBanner extends StatefulWidget {
  final VoidCallback? onUpgraded;
  const UpgradePremiumBanner({super.key, this.onUpgraded});

  @override
  State<UpgradePremiumBanner> createState() => _UpgradePremiumBannerState();
}

class _UpgradePremiumBannerState extends State<UpgradePremiumBanner> {
  bool _loading = false;

  Future<void> _buyPremium() async {
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PaymentDialog(
        title: 'Premium Üyelik Satın Al',
        description: 'Sınırsız erişim, altın rozet ve akıllı eşleşme özellikleri için ödeme yapın.',
        amount: 10.0,
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final success = await PremiumService.upgradeToPremium(user.uid);
    setState(() => _loading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tebrikler! Premium üyelik aktif edildi.')),
        );
      }
      widget.onUpgraded?.call();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız oldu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Premium\'a Geçin!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Sadece \$10 ile öne çıkın ve sınırsız özelliklere erişin.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : ElevatedButton(
                  onPressed: _buyPremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('SATIN AL'),
                ),
        ],
      ),
    );
  }
}
