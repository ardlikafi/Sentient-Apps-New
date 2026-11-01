import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentient/core/services/firebase_service.dart';
import 'package:sentient/core/services/notification_service.dart';
import 'package:sentient/core/services/simulated_order_service.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isPremium => _userData?['is_premium'] == true || SimulatedOrderService.isPremium;

  void setPremiumInstant(bool value, {String? tier, String? duration}) {
    if (_userData != null) {
      _userData!['is_premium'] = value;
      if (tier != null) _userData!['subscription_tier'] = tier;
      if (duration != null) _userData!['subscription_duration'] = duration;
    }
    SimulatedOrderService.togglePremium(value, tier: tier);
    notifyListeners();
  }

  UserProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    // Dengarkan perubahan state auth Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        fetchUser();
      } else {
        _userData = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await FirebaseService.getCurrentUser();
      _userData = data;
      if (data != null) {
        if (data['is_premium'] == true || data['isPremium'] == true) {
          SimulatedOrderService.togglePremium(true, tier: data['subscription_tier']?.toString());
        }
        if (data['id'] != null) {
          final uid = data['id'].toString();
          NotificationService.syncUserFCMToken();
          NotificationService.startPresenceSystem();
          NotificationService.startGlobalListeners(uid);
        }
      }
    } catch (e) {
      print('Error fetching user data in provider: $e');
      _userData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    await fetchUser();
  }
}
