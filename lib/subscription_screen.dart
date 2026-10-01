import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'demo_payment_page.dart';
import 'simulated_order_service.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isProcessing = false;

  Future<void> _handleSubscriptionPurchase(String planName, String duration, int price) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please login first');
        return;
      }

      // Get user data
      final userData = await FirebaseService.getCurrentUser();
      if (userData == null) {
        _showErrorSnackBar('Failed to get user data');
        return;
      }

      // Navigate to demo payment page
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DemoPaymentPage(
            planName: planName,
            price: price,
            userEmail: userData['email'] ?? '',
            userName: userData['username'] ?? '',
          ),
        ),
      );

      // If payment was successful
      if (result == true) {
        await FirebaseService.updatePremiumStatus(true);
        _showSuccessSnackBar('Payment successful! Subscription activated.');
        if (mounted) {
          setState(() {});
        }
      }

    } catch (e) {
      _showErrorSnackBar('Payment error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> benefits = [
      'Unlimited access to all courses',
      'Exclusive articles',
      'Special discounts in the shop',
    ];

    return Scaffold(
      backgroundColor: kVeryLightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: kPrimaryBlue.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          "Subscription",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000A26),
                Color(0xFF001759),
                Color(0xFF00207B),
              ],
              stops: [0.0, 0.66, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Image.asset(
                'assets/images/img_logo.png',
                height: 80,
                errorBuilder: (c, e, s) =>
                const Icon(Icons.workspace_premium, color: kPrimaryBlue, size: 80),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Your Subscription',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kDarkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access all courses, improve faster and play smarter\nupgrade your plan today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kDarkBlue.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kLightBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Available Payment Methods',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All payments are processed securely via Flip',
                      style: TextStyle(
                        fontSize: 12,
                        color: kDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _PaymentMethodIcon(icon: Icons.account_balance_wallet, name: 'GoPay'),
                        _PaymentMethodIcon(icon: Icons.shopping_bag, name: 'ShopeePay'),
                        _PaymentMethodIcon(icon: Icons.phone_android, name: 'DANA'),
                        _PaymentMethodIcon(icon: Icons.phone_iphone, name: 'OVO'),
                        _PaymentMethodIcon(icon: Icons.qr_code_scanner, name: 'QRIS'),
                        _PaymentMethodIcon(icon: Icons.account_balance, name: 'Virtual Account'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SubscriptionTierCard(
                iconPath: 'assets/images/ic_pawn.png',
                tierName: 'Pawn Tier',
                duration: '1 Month',
                price: 99000,
                benefits: benefits,
                isProcessing: _isProcessing,
                onPurchase: () => _handleSubscriptionPurchase('Pawn Tier', '1 Month', 99000),
              ),
              SubscriptionTierCard(
                iconPath: 'assets/images/ic_knight.png',
                tierName: 'Knight Tier',
                duration: '3 Month',
                price: 269000,
                benefits: benefits,
                isProcessing: _isProcessing,
                onPurchase: () => _handleSubscriptionPurchase('Knight Tier', '3 Month', 269000),
              ),
              SubscriptionTierCard(
                iconPath: 'assets/images/ic_queen.png',
                tierName: 'Queen Tier',
                duration: '6 Month',
                price: 499000,
                benefits: benefits,
                isProcessing: _isProcessing,
                onPurchase: () => _handleSubscriptionPurchase('Queen Tier', '6 Month', 499000),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionTierCard extends StatelessWidget {
  final String iconPath;
  final String tierName;
  final String duration;
  final int price;
  final List<String> benefits;
  final VoidCallback onPurchase;
  final bool isProcessing;

  const SubscriptionTierCard({
    super.key,
    required this.iconPath,
    required this.tierName,
    required this.duration,
    required this.price,
    required this.benefits,
    required this.onPurchase,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentPremium = SimulatedOrderService.isPremium;
    
    // Choose beautiful gradient based on Tier Name
    final List<Color> gradientColors;
    final Color textColor;
    final Color buttonBgColor;
    final Color buttonTextColor;
    
    if (tierName.contains('Queen')) {
      gradientColors = const [Color(0xFFD4AF37), Color(0xFFFFDF00), Color(0xFFAA7C11)]; // Luxury Gold
      textColor = const Color(0xFF1A1A2E);
      buttonBgColor = const Color(0xFF1A1A2E);
      buttonTextColor = const Color(0xFFFFDF00);
    } else if (tierName.contains('Knight')) {
      gradientColors = const [Color(0xFFE5E4E2), Color(0xFFB0C4DE), Color(0xFF708090)]; // Platinum Silver
      textColor = const Color(0xFF000A26);
      buttonBgColor = const Color(0xFF000A26);
      buttonTextColor = Colors.white;
    } else {
      gradientColors = const [Color(0xFF0F52BA), Color(0xFF00207B), Color(0xFF000A26)]; // Sapphire Blue
      textColor = Colors.white;
      buttonBgColor = Colors.white;
      buttonTextColor = const Color(0xFF0F52BA);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                iconPath,
                height: 48,
                errorBuilder: (c, e, s) => Icon(Icons.shield, color: textColor, size: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tierName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: textColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (isCurrentPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.8),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBgColor,
                  foregroundColor: buttonTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black38,
                ),
                onPressed: isProcessing ? null : onPurchase,
                child: isProcessing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(buttonTextColor),
                        ),
                      )
                    : Text(
                        isCurrentPremium ? 'Renew' : 'Buy Now',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: textColor.withOpacity(0.2), height: 1),
          const SizedBox(height: 16),
          Text(
            'Benefit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: textColor,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          ...benefits.map((benefit) => _BenefitItem(text: benefit, color: textColor)).toList(),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BenefitItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodIcon extends StatelessWidget {
  final IconData icon;
  final String name;

  const _PaymentMethodIcon({
    required this.icon,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: kPrimaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: kDarkBlue.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
