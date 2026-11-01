import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MidtransService {
  // Ganti dengan credential dari Midtrans Dashboard
  static const String _serverKey = 'SB-Mid-server-XXXXXXXXXXXXXXXX';
  static const String _clientKey = 'SB-Mid-client-XXXXXXXXXXXXXXXX';
  static const String _baseUrl = 'https://api.sandbox.midtrans.com/v2';

  // Create transaction token
  static Future<String?> createTransactionToken({
    required String orderId,
    required int grossAmount,
    required Map<String, dynamic> customerDetails,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/charge'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64.encode(utf8.encode('$_serverKey:'))}',
        },
        body: jsonEncode({
          'payment_type': 'gopay',
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': grossAmount,
          },
          'customer_details': customerDetails,
          'item_details': items,
          'gopay': {
            'enable_callback': true,
            'callback_url': 'https://your-website.com/callback',
          },
          // Alternative payment methods
          'shopeepay': {
            'enable_callback': true,
            'callback_url': 'https://your-website.com/callback',
          },
          'dana': {
            'enable_callback': true,
            'callback_url': 'https://your-website.com/callback',
          },
          'ovo': {
            'enable_callback': true,
            'callback_url': 'https://your-website.com/callback',
          },
          'qris': {
            'enable_callback': true,
            'callback_url': 'https://your-website.com/callback',
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        if (kDebugMode) {
          print('Failed to create transaction: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating transaction token: $e');
      }
      return null;
    }
  }

  // Start payment with webview
  static Future<bool> startPaymentWebview({
    required String snapToken,
  }) async {
    try {
      // Open Snap URL untuk multiple payment methods
      final snapUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken';
      
      if (kDebugMode) {
        print('Opening payment URL: $snapUrl');
      }
      
      // Buka di browser eksternal
      // Untuk implementasi webview, gunakan package flutter_webview
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Payment error: $e');
      }
      return false;
    }
  }

  // Helper untuk subscription payment
  static Future<Map<String, dynamic>?> processSubscriptionPayment({
    required String userId,
    required String planName,
    required int price,
    required String customerEmail,
    required String customerName,
  }) async {
    final orderId = 'SUB_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final customerDetails = {
      'first_name': customerName.split(' ').first,
      'last_name': customerName.split(' ').last,
      'email': customerEmail,
      'phone': '+628123456789',
    };

    final items = [
      {
        'id': 'SUB_$planName',
        'price': price,
        'quantity': 1,
        'name': '$planName Subscription',
        'category': 'Subscription',
      }
    ];

    // Create transaction token
    final token = await createTransactionToken(
      orderId: orderId,
      grossAmount: price,
      customerDetails: customerDetails,
      items: items,
    );

    if (token == null) {
      return null;
    }

    return {
      'token': token,
      'orderId': orderId,
      'status': 'pending',
    };
  }

  // Helper untuk product purchase
  static Future<Map<String, dynamic>?> processProductPurchase({
    required String userId,
    required String productId,
    required String productName,
    required int price,
    required String customerEmail,
    required String customerName,
  }) async {
    final orderId = 'PROD_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final customerDetails = {
      'first_name': customerName.split(' ').first,
      'last_name': customerName.split(' ').last,
      'email': customerEmail,
      'phone': '+628123456789',
    };

    final items = [
      {
        'id': productId,
        'price': price,
        'quantity': 1,
        'name': productName,
        'category': 'Product',
      }
    ];

    // Create transaction token
    final token = await createTransactionToken(
      orderId: orderId,
      grossAmount: price,
      customerDetails: customerDetails,
      items: items,
    );

    if (token == null) {
      return null;
    }

    return {
      'token': token,
      'orderId': orderId,
      'status': 'pending',
    };
  }

  // Helper untuk course enrollment
  static Future<Map<String, dynamic>?> processCourseEnrollment({
    required String userId,
    required String courseId,
    required String courseName,
    required int price,
    required String customerEmail,
    required String customerName,
  }) async {
    final orderId = 'COURSE_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final customerDetails = {
      'first_name': customerName.split(' ').first,
      'last_name': customerName.split(' ').last,
      'email': customerEmail,
      'phone': '+628123456789',
    };

    final items = [
      {
        'id': courseId,
        'price': price,
        'quantity': 1,
        'name': courseName,
        'category': 'Course',
      }
    ];

    // Create transaction token
    final token = await createTransactionToken(
      orderId: orderId,
      grossAmount: price,
      customerDetails: customerDetails,
      items: items,
    );

    if (token == null) {
      return null;
    }

    return {
      'token': token,
      'orderId': orderId,
      'status': 'pending',
    };
  }

  // Get payment status
  static Future<Map<String, dynamic>?> getPaymentStatus(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$orderId/status'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64.encode(utf8.encode('$_serverKey:'))}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('Failed to get payment status: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment status: $e');
      }
      return null;
    }
  }
}
