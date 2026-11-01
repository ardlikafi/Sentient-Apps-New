import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentient/core/services/simulated_order_service.dart';
import 'package:sentient/features/profile/subscription_screen.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

// =========================================================================
// 1. GORGEOUS PREMIUM PAYWALL DIALOG
// =========================================================================
class PremiumPaywallDialog extends StatelessWidget {
  const PremiumPaywallDialog({super.key});

  static Future<bool?> show(BuildContext context) async {
    final shouldUpgrade = await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumPaywallDialog(),
    );
    if (shouldUpgrade == true && context.mounted) {
      final res = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionScreen(),
        ),
      );
      return res;
    }
    return shouldUpgrade;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07143B),
              Color(0xFF000A26),
            ],
          ),
          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold Crown Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'SENTIENT PREMIUM',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock Chess Mastery',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This is a premium feature. Upgrade your tier to get full, unrestricted access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            // Benefits List
            _buildBenefitRow(Icons.school, 'Unlock All Premium Chess Courses'),
            _buildBenefitRow(Icons.analytics, 'Advanced Grandmaster-Level AI Opponent'),
            _buildBenefitRow(Icons.palette, 'Exclusive Neon & Marble Board Skins'),
            _buildBenefitRow(Icons.support_agent, 'Priority 24/7 Premium Support'),
            _buildBenefitRow(Icons.block, 'Fully Ad-Free Chess Training'),

            const SizedBox(height: 24),
            
            // Buy / Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: kDarkBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xE6FFFFFF),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 2. STUNNING CHECKOUT BOTTOM SHEET
// =========================================================================
class CheckoutBottomSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final String size;

  const CheckoutBottomSheet({
    super.key,
    required this.product,
    required this.size,
  });

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedCourier = 'JNE Express';
  String _selectedPayment = 'BCA Virtual Account';

  final Map<String, int> _couriers = {
    'JNE Express': 15000,
    'J&T Express': 18000,
    'SiCepat Reguler': 12000,
  };

  final List<String> _payments = [
    'BCA Virtual Account',
    'Mandiri Virtual Account',
    'GoPay E-Wallet',
    'OVO Cash',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  int get _itemPrice => widget.product['price'] as int? ?? 0;
  int get _shippingCost => _couriers[_selectedCourier] ?? 15000;
  int get _adminFee => 2000;
  int get _totalAmount => _itemPrice + _shippingCost + _adminFee;

  void _processPayment() {
    if (!_formKey.currentState!.validate()) return;

    // Show gorgeous simulated payment process dialog
    Navigator.pop(context); // Close bottom sheet
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentProcessingDialog(
        onSuccess: () {
          // Add order
          final order = {
            'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
            'productName': widget.product['name'],
            'productImage': widget.product['imageUrl'],
            'size': widget.size,
            'price': _itemPrice,
            'shippingCourier': _selectedCourier,
            'shippingCost': _shippingCost,
            'paymentMethod': _selectedPayment,
            'recipientName': _nameController.text,
            'phone': _phoneController.text,
            'address': '${_addressController.text}, ${_cityController.text}',
            'totalPaid': _totalAmount,
            'status': 'Processing', // Processing, Shipped, Completed
            'date': DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
            'trackingNumber': 'TRACK-STN-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
          };
          SimulatedOrderService.addOrder(order);

          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase Successful! Your order is being processed.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8F0F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle indicator
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Order Checkout',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPrimaryBlue.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              widget.product['imageUrl'],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 70,
                                height: 70,
                                color: kVeryLightBlue,
                                child: const Icon(Icons.broken_image, color: kPrimaryBlue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: kDarkBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${widget.size}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${NumberFormat.decimalPattern('id_ID').format(_itemPrice)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: kPrimaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Shipping Address Header
                    _buildSectionHeader('Shipping Address', Icons.local_shipping),
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Recipient Name',
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty ? 'Recipient name cannot be empty' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Phone number cannot be empty' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Full Address',
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      validator: (value) => value!.isEmpty ? 'Address cannot be empty' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _cityController,
                      label: 'City & Postal Code',
                      icon: Icons.map_outlined,
                      validator: (value) => value!.isEmpty ? 'City & postal code are required' : null,
                    ),

                    const SizedBox(height: 24),

                    // Courier Dropdown
                    _buildSectionHeader('Shipping Service / Courier', Icons.delivery_dining),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCourier,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: kPrimaryBlue),
                          items: _couriers.keys.map((String courier) {
                            return DropdownMenuItem<String>(
                              value: courier,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    courier,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: kDarkBlue),
                                  ),
                                  Text(
                                    '+Rp ${NumberFormat.decimalPattern('id_ID').format(_couriers[courier])}',
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCourier = value!;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Method Dropdown
                    _buildSectionHeader('Payment Method', Icons.payment),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPayment,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: kPrimaryBlue),
                          items: _payments.map((String payment) {
                            return DropdownMenuItem<String>(
                              value: payment,
                              child: Text(
                                payment,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: kDarkBlue),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPayment = value!;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Summary Details
                    _buildSectionHeader('Payment Details', Icons.receipt_long),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Item Price', _itemPrice),
                    _buildSummaryRow('Shipping Cost', _shippingCost),
                    _buildSummaryRow('Admin Fee', _adminFee),
                    const Divider(color: Colors.black26),
                    _buildSummaryRow('Total Payment', _totalAmount, isTotal: true),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Button Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  )
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _processPayment,
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kDarkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: kDarkBlue),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 13, fontFamily: 'Poppins'),
        prefixIcon: Icon(icon, color: kPrimaryBlue.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? kDarkBlue : Colors.black54,
            ),
          ),
          Text(
            'Rp ${NumberFormat.decimalPattern('id_ID').format(value)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? kPrimaryBlue : kDarkBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. STEPPED PAYMENT GATEWAY LOADING DIALOG
// =========================================================================
class _PaymentProcessingDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _PaymentProcessingDialog({required this.onSuccess});

  @override
  State<_PaymentProcessingDialog> createState() => _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<_PaymentProcessingDialog> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Validating Shipping Address...',
    'Connecting to Secure Gateway...',
    'Generating Virtual Account Billing Code...',
    'Verifying Transaction...',
    'Success! Payment Received.',
  ];

  @override
  void initState() {
    super.initState();
    _startSimulatedSteps();
  }

  void _startSimulatedSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: kDarkBlue,
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular progress or Success checkmark
            _currentStep == _steps.length - 1
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 36),
                  )
                : const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                    strokeWidth: 3.5,
                  ),
            const SizedBox(height: 24),
            
            const Text(
              'Payment Gateway',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Dynamic Step text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _steps[_currentStep],
                key: ValueKey<int>(_currentStep),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: _currentStep == _steps.length - 1 ? Colors.green : Colors.white70,
                  fontWeight: _currentStep == _steps.length - 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 4. MY ORDERS DETAILED BOTTOM SHEET
// =========================================================================
class MyOrdersSheet extends StatefulWidget {
  const MyOrdersSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MyOrdersSheet(),
    );
  }

  @override
  State<MyOrdersSheet> createState() => _MyOrdersSheetState();
}

class _MyOrdersSheetState extends State<MyOrdersSheet> {
  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;
    final orders = SimulatedOrderService.orders;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F0F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag indicator
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Orders',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kDarkBlue),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 72,
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your purchase history and order details will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Dynamic status colors
    Color statusBgColor = Colors.orange.withOpacity(0.15);
    Color statusTextColor = Colors.orange;
    if (order['status'] == 'Shipped' || order['status'] == 'Dikirim') {
      statusBgColor = Colors.blue.withOpacity(0.15);
      statusTextColor = Colors.blue;
    } else if (order['status'] == 'Completed' || order['status'] == 'Selesai') {
      statusBgColor = Colors.green.withOpacity(0.15);
      statusTextColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: kPrimaryBlue.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Date & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['orderId'],
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: kDarkBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order['status'],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order['date'],
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
          const Divider(height: 24, color: Colors.black12),

          // Product Details
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  order['productImage'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 50,
                    height: 50,
                    color: kVeryLightBlue,
                    child: const Icon(Icons.broken_image, size: 20, color: kPrimaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['productName'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${order['size']} • Courier: ${order['shippingCourier']}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.black12),

          // Total Paid & Shipping Address Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Purchase:',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black45),
                  ),
                  Text(
                    'Rp ${NumberFormat.decimalPattern('id_ID').format(order['totalPaid'])}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              
              // Action buttons depending on state
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue.withOpacity(0.08),
                  foregroundColor: kPrimaryBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  _showOrderDetailDialog(order);
                },
                child: const Text(
                  'Details',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showOrderDetailDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Details',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBlue),
              ),
              const SizedBox(height: 16),
              
              _buildDetailInfoRow('Recipient', order['recipientName']),
              _buildDetailInfoRow('Phone', order['phone']),
              _buildDetailInfoRow('Address', order['address']),
              _buildDetailInfoRow('Payment Method', order['paymentMethod']),
              _buildDetailInfoRow('Tracking Number', order['trackingNumber']),
              const Divider(height: 24),
              _buildDetailPriceRow('Item Subtotal', order['price']),
              _buildDetailPriceRow('Shipping Subtotal', order['shippingCost']),
              _buildDetailPriceRow('Admin Fee', 2000),
              const Divider(color: Colors.black26),
              _buildDetailPriceRow('Total Bill', order['totalPaid'], isBold: true),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: kDarkBlue, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDetailPriceRow(String label, int value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? kDarkBlue : Colors.black54,
            ),
          ),
          Text(
            'Rp ${NumberFormat.decimalPattern('id_ID').format(value)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? kPrimaryBlue : kDarkBlue,
            ),
          ),
        ],
      ),
    );
  }
}
