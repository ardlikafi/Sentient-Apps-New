import 'dart:async';

class SimulatedOrderService {
  static bool isPremium = false;
  static String activeTier = 'Queen Tier';
  static final List<Map<String, dynamic>> orders = [];

  static final StreamController<void> _orderController = StreamController<void>.broadcast();
  static Stream<void> get orderStream => _orderController.stream;

  static void addOrder(Map<String, dynamic> order) {
    orders.insert(0, order); // insert at the top (newest first)
    _orderController.add(null);
  }

  static void togglePremium(bool value, {String? tier}) {
    isPremium = value;
    if (tier != null && tier.isNotEmpty) {
      activeTier = tier;
    }
    _orderController.add(null);
  }

  static void notifyChange() {
    _orderController.add(null);
  }
}
