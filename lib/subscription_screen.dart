import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

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
                'assets/images/ic_gem.png',
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
                'Access all courses, improve faster, and play smarter\nupgrade your plan today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kDarkBlue.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              SubscriptionTierCard(
                iconPath: 'assets/images/ic_pawn.png',
                tierName: 'Pawn Tier',
                duration: '1 Month',
                benefits: benefits,
              ),
              SubscriptionTierCard(
                iconPath: 'assets/images/ic_knight.png',
                tierName: 'Knight Tier',
                duration: '3 Month',
                benefits: benefits,
              ),
              SubscriptionTierCard(
                iconPath: 'assets/images/ic_queen.png',
                tierName: 'Queen Tier',
                duration: '6 Month',
                benefits: benefits,
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
  final List<String> benefits;

  const SubscriptionTierCard({
    super.key,
    required this.iconPath,
    required this.tierName,
    required this.duration,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kPrimaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(iconPath, height: 48, errorBuilder: (c,e,s) => const Icon(Icons.shield, color: Colors.white, size: 48)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tierName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLightBlue.withOpacity(0.8),
                  foregroundColor: kPrimaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // TODO: Tambahkan logika pembelian
                },
                child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Benefit',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...benefits.map((benefit) => _BenefitItem(text: benefit)).toList(),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String text;
  const _BenefitItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}