import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

class DemoPaymentPage extends StatefulWidget {
  final String planName;
  final String duration;
  final int price;
  final String userEmail;
  final String userName;

  const DemoPaymentPage({
    super.key,
    required this.planName,
    this.duration = '1 Month',
    required this.price,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<DemoPaymentPage> createState() => _DemoPaymentPageState();
}

class _DemoPaymentPageState extends State<DemoPaymentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _orderId;
  int _secondsLeft = 15 * 60; // 15:00 countdown
  Timer? _countdownTimer;

  // Selected Bank for Virtual Account
  String _selectedBank = 'BCA';
  final Map<String, String> _vaNumbers = {
    'BCA': '8277 0812 4589 1234',
    'Mandiri': '8870 0812 4589 1234',
    'BRI': '1280 0812 4589 1234',
    'BNI': '9880 0812 4589 1234',
  };

  // Selected E-Wallet
  String _selectedEWallet = 'GoPay';
  final TextEditingController _phoneController = TextEditingController(text: '0812-3456-7890');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final randomNum = Random().nextInt(90000) + 10000;
    _orderId = 'INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-SNT$randomNum';

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text.replaceAll(' ', '')));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _simulatePaymentVerification() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PaymentVerificationDialog(
        orderId: _orderId,
        planName: widget.planName,
        duration: widget.duration,
        price: widget.price,
        onSuccess: () {
          Navigator.of(dialogCtx).pop(); // Close verification dialog
          _showCelebrationDialog();
        },
      ),
    );
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (celebrateCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF000A26),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Pulsing Checkmark
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF10B981), width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Payment Successful! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Congratulations! Your account is now active as a Sentient Premium All-Access Member.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Subscription Plan', widget.planName),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Duration', widget.duration),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                      'Total Paid',
                      'Rp ${NumberFormat.decimalPattern('id_ID').format(widget.price)}',
                      isBold: true,
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _buildPerkCheck('Full Access to All Video Courses'),
                    const SizedBox(height: 4),
                    _buildPerkCheck('AI Grandmaster Engine Unlocked'),
                    const SizedBox(height: 4),
                    _buildPerkCheck('Exclusive Badge on Profile & Tournaments'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: const Color(0xFF000A26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.of(celebrateCtx).pop(); // Close celebration dialog
                    Navigator.of(context).pop(true); // Return TRUE to SubscriptionScreen!
                  },
                  child: const Text(
                    'Mulai Belajar Sekarang 🚀',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPerkCheck(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = 'Rp ${NumberFormat.decimalPattern('id_ID').format(widget.price)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: Colors.amber, size: 18),
            SizedBox(width: 8),
            Text(
              'Secure Payment Gateway',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Live Countdown Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFEF3C7),
            child: Row(
              children: [
                const Icon(Icons.alarm_rounded, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Selesaikan transaksi sebelum batas waktu:',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTimer(_secondsLeft),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice & Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: kPrimaryBlue,
                                  child: Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sentient Platform',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkBlue),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _orderId,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'monospace'),
                            ),
                            GestureDetector(
                              onTap: () => _copyToClipboard(_orderId, 'Order Number'),
                              child: const Text(
                                'Copy',
                                style: TextStyle(color: kPrimaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.planName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDarkBlue),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'All-Access Membership (${widget.duration})',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              formattedPrice,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDarkBlue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Service Fee & VAT (11%)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Payment',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDarkBlue),
                            ),
                            Text(
                              formattedPrice,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Payment Method Tabs
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDarkBlue),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: kPrimaryBlue,
                      indicatorWeight: 3,
                      labelColor: kPrimaryBlue,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'QRIS', icon: Icon(Icons.qr_code_2_rounded, size: 20)),
                        Tab(text: 'Virtual Account', icon: Icon(Icons.account_balance_rounded, size: 20)),
                        Tab(text: 'E-Wallet', icon: Icon(Icons.account_balance_wallet_rounded, size: 20)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab Views
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // TAB 1: QRIS
                        _buildQrisSection(formattedPrice),

                        // TAB 2: Virtual Account
                        _buildVirtualAccountSection(formattedPrice),

                        // TAB 3: E-Wallet
                        _buildEWalletSection(formattedPrice),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Transfer', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        Text(
                          formattedPrice,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      onPressed: _simulatePaymentVerification,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('I Have Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: QRIS
  // ==========================================
  Widget _buildQrisSection(String formattedPrice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'QRIS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
                ),
              ),
              const Text('NMID: ID1020038192801', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),

          // QR Code Graphic
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                painter: _RealisticQrPainter(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Scan via GoPay, OVO, DANA, BCA, Mandiri, ShopeePay, etc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
          ),
          const Spacer(),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryBlue,
              side: const BorderSide(color: kPrimaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QRIS image saved to phone gallery.')),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Save QRIS Image'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: VIRTUAL ACCOUNT
  // ==========================================
  Widget _buildVirtualAccountSection(String formattedPrice) {
    final vaNumber = _vaNumbers[_selectedBank] ?? '8277 0812 4589 1234';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Virtual Account Bank:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkBlue)),
          const SizedBox(height: 10),

          // Bank Selector Row
          Row(
            children: ['BCA', 'Mandiri', 'BRI', 'BNI'].map((bank) {
              final isSel = _selectedBank == bank;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBank = bank),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? kPrimaryBlue : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSel ? kPrimaryBlue : const Color(0xFFCBD5E1)),
                      ),
                      child: Center(
                        child: Text(
                          bank,
                          style: TextStyle(
                            color: isSel ? Colors.white : kDarkBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // VA Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Virtual Account Number ($_selectedBank)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vaNumber,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: kDarkBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: kPrimaryBlue, size: 20),
                      onPressed: () => _copyToClipboard(vaNumber, 'Virtual Account Number'),
                      tooltip: 'Copy VA Number',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Text('Quick Transfer Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kDarkBlue)),
          const SizedBox(height: 6),
          _buildStepRow('1', 'Open $_selectedBank m-Banking > select Transfer Virtual Account'),
          _buildStepRow('2', 'Enter the VA number above and total amount $formattedPrice'),
          _buildStepRow('3', 'Confirm merchant name "Sentient Academy" and complete transaction'),
        ],
      ),
    );
  }

  Widget _buildStepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: kPrimaryBlue.withValues(alpha: 0.15),
            child: Text(num, style: const TextStyle(fontSize: 9, color: kPrimaryBlue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: E-WALLET
  // ==========================================
  Widget _buildEWalletSection(String formattedPrice) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Digital Wallet:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkBlue)),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: ['GoPay', 'DANA', 'OVO', 'ShopeePay'].map((ewallet) {
              final isSel = _selectedEWallet == ewallet;
              return ChoiceChip(
                label: Text(ewallet),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _selectedEWallet = ewallet);
                },
                selectedColor: kPrimaryBlue,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Text('Account Phone Number:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_android_rounded, color: kPrimaryBlue),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'After tapping "I Have Paid", you will be redirected to the $_selectedEWallet app for authorization.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// REALISTIC VERIFICATION DIALOG (Simulating Bank Network Check)
// =========================================================================
class _PaymentVerificationDialog extends StatefulWidget {
  final String orderId;
  final String planName;
  final String duration;
  final int price;
  final VoidCallback onSuccess;

  const _PaymentVerificationDialog({
    required this.orderId,
    required this.planName,
    required this.duration,
    required this.price,
    required this.onSuccess,
  });

  @override
  State<_PaymentVerificationDialog> createState() => _PaymentVerificationDialogState();
}

class _PaymentVerificationDialogState extends State<_PaymentVerificationDialog> {
  int _step = 1;

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  void _runSimulation() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _step = 2);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _step = 3);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _step == 1
                  ? 'Connecting to Gateway...'
                  : _step == 2
                      ? 'Verifying Transaction...'
                      : 'Payment Confirmed!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDarkBlue),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 1
                  ? 'Checking payment system records...'
                  : _step == 2
                      ? 'Syncing Sentient All-Access status...'
                      : 'Activating your membership...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// REALISTIC QR PAINTER (Indistinguishable from real QRIS matrix)
// =========================================================================
class _RealisticQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final w = size.width;
    final h = size.height;
    const int grid = 21;
    final cellSize = w / grid;

    // Draw the 3 finder squares (Top-Left, Top-Right, Bottom-Left)
    void drawFinder(double x, double y) {
      // Outer 7x7 square
      canvas.drawRect(Rect.fromLTWH(x, y, cellSize * 7, cellSize * 7), paint);
      // Inner 5x5 white square
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(x + cellSize, y + cellSize, cellSize * 5, cellSize * 5), whitePaint);
      // Center 3x3 black square
      canvas.drawRect(Rect.fromLTWH(x + cellSize * 2, y + cellSize * 2, cellSize * 3, cellSize * 3), paint);
    }

    drawFinder(0, 0);
    drawFinder(w - cellSize * 7, 0);
    drawFinder(0, h - cellSize * 7);

    // Pseudorandom consistent pattern dots
    final rand = Random(42);
    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        // Skip finder areas
        if (r < 7 && c < 7) continue;
        if (r < 7 && c >= grid - 7) continue;
        if (r >= grid - 7 && c < 7) continue;
        // Skip center logo area
        if (r >= 8 && r <= 12 && c >= 8 && c <= 12) continue;

        if (rand.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.95, cellSize * 0.95),
            paint,
          );
        }
      }
    }

    // Center Logo Badge
    final centerRect = Rect.fromCenter(center: Offset(w / 2, h / 2), width: cellSize * 5, height: cellSize * 5);
    final logoBg = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(centerRect, const Radius.circular(6)), logoBg);
    final borderPaint = Paint()
      ..color = kPrimaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(centerRect, const Radius.circular(6)), borderPaint);

    // Inner Blue Chess Symbol
    final innerDot = Paint()..color = kPrimaryBlue;
    canvas.drawCircle(Offset(w / 2, h / 2), cellSize * 1.5, innerDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
