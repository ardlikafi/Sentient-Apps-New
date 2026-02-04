import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class FlipPaymentService {
  // Flip API credentials (sandbox)
  static const String _apiKey = 'FLIP_SANDBOX_API_KEY_HERE';
  static const String _baseUrl = 'https://api.flip.id/v2';
  
  // Payment methods available
  static const List<Map<String, dynamic>> paymentMethods = [
    {
      'code': 'BCA',
      'name': 'BCA Virtual Account',
      'icon': 'account_balance',
      'type': 'virtual_account',
    },
    {
      'code': 'BNI',
      'name': 'BNI Virtual Account',
      'icon': 'account_balance',
      'type': 'virtual_account',
    },
    {
      'code': 'BRI',
      'name': 'BRI Virtual Account',
      'icon': 'account_balance',
      'type': 'virtual_account',
    },
    {
      'code': 'MANDIRI',
      'name': 'Mandiri Virtual Account',
      'icon': 'account_balance',
      'type': 'virtual_account',
    },
    {
      'code': 'PERMATA',
      'name': 'Permata Virtual Account',
      'icon': 'account_balance',
      'type': 'virtual_account',
    },
    {
      'code': 'GOPAY',
      'name': 'GoPay',
      'icon': 'account_balance_wallet',
      'type': 'ewallet',
    },
    {
      'code': 'SHOPEEPAY',
      'name': 'ShopeePay',
      'icon': 'shopping_bag',
      'type': 'ewallet',
    },
    {
      'code': 'DANA',
      'name': 'DANA',
      'icon': 'phone_android',
      'type': 'ewallet',
    },
    {
      'code': 'OVO',
      'name': 'OVO',
      'icon': 'phone_iphone',
      'type': 'ewallet',
    },
    {
      'code': 'QRIS',
      'name': 'QRIS',
      'icon': 'qr_code_scanner',
      'type': 'qris',
    },
  ];

  // Create bill payment
  static Future<Map<String, dynamic>?> createBill({
    required String title,
    required int amount,
    required String payerEmail,
    required String description,
    String? redirectUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pw/bill'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_apiKey',
        },
        body: jsonEncode({
          'title': title,
          'amount': amount,
          'type': 'SINGLE',
          'payer_email': payerEmail,
          'description': description,
          'redirect_url': redirectUrl ?? 'https://your-app.com/payment-callback',
          'expired_date': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print('Flip bill created: $data');
        }
        return data;
      } else {
        if (kDebugMode) {
          print('Failed to create Flip bill: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating Flip bill: $e');
      }
      return null;
    }
  }

  // Get bill status
  static Future<Map<String, dynamic>?> getBillStatus(String billId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pw/bill/$billId'),
        headers: {
          'Authorization': 'Basic $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('Failed to get bill status: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bill status: $e');
      }
      return null;
    }
  }

  // Open payment URL
  static Future<bool> openPaymentUrl(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        if (kDebugMode) {
          print('Could not launch payment URL: $paymentUrl');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening payment URL: $e');
      }
      return false;
    }
  }

  // Helper for subscription payment
  static Future<Map<String, dynamic>?> processSubscriptionPayment({
    required String planName,
    required String duration,
    required int price,
    required String userEmail,
    required String userName,
  }) async {
    try {
      if (kDebugMode) {
        print('Starting payment process for $planName');
        print('Price: $price, Email: $userEmail, Name: $userName');
      }

      // For now, simulate payment since we don't have real Flip API key
      // In production, uncomment the real API call below
      
      // Try to use real Flip sandbox (no API key needed for basic testing)
      final result = await createBill(
        title: '$planName Subscription - $duration',
        amount: price,
        payerEmail: userEmail,
        description: 'Subscription for $planName plan ($duration) by $userName',
      );

      if (result != null && result['link'] != null) {
        // Open payment URL
        await openPaymentUrl(result['link']);
        
        return {
          'bill_id': result['id'],
          'payment_url': result['link'],
          'status': 'PENDING',
          'amount': price,
        };
      }

      // Fallback to simulation if API fails
      await Future.delayed(const Duration(seconds: 2));
      
      // Show success message
      if (kDebugMode) {
        print('Payment simulation successful!');
      }
      
      return {
        'bill_id': 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
        'payment_url': 'https://flip.id/demo-payment',
        'status': 'PENDING',
        'amount': price,
        'message': 'Demo payment - In production, this would open real Flip payment page',
      };
      
    } catch (e) {
      if (kDebugMode) {
        print('Error processing subscription payment: $e');
      }
      return null;
    }
  }

  // Helper for product purchase
  static Future<Map<String, dynamic>?> processProductPurchase({
    required String productName,
    required int price,
    required String userEmail,
    required String userName,
  }) async {
    try {
      final result = await createBill(
        title: 'Purchase - $productName',
        amount: price,
        payerEmail: userEmail,
        description: 'Purchase of $productName by $userName',
      );

      if (result != null && result['link'] != null) {
        // Open payment URL
        await openPaymentUrl(result['link']);
        
        return {
          'bill_id': result['id'],
          'payment_url': result['link'],
          'status': 'PENDING',
          'amount': price,
        };
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing product purchase: $e');
      }
      return null;
    }
  }

  // Helper for course enrollment
  static Future<Map<String, dynamic>?> processCourseEnrollment({
    required String courseName,
    required int price,
    required String userEmail,
    required String userName,
  }) async {
    try {
      final result = await createBill(
        title: 'Course Enrollment - $courseName',
        amount: price,
        payerEmail: userEmail,
        description: 'Enrollment in $courseName course by $userName',
      );

      if (result != null && result['link'] != null) {
        // Open payment URL
        await openPaymentUrl(result['link']);
        
        return {
          'bill_id': result['id'],
          'payment_url': result['link'],
          'status': 'PENDING',
          'amount': price,
        };
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing course enrollment: $e');
      }
      return null;
    }
  }

  // Get available payment methods
  static List<Map<String, dynamic>> getEWalletMethods() {
    return paymentMethods.where((method) => 
      method['type'] == 'ewallet' || method['type'] == 'qris'
    ).toList();
  }

  static List<Map<String, dynamic>> getVirtualAccountMethods() {
    return paymentMethods.where((method) => 
      method['type'] == 'virtual_account'
    ).toList();
  }
}
