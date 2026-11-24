import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;
  Cart cart = const Cart();
  bool loading = false;
  bool busy = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      cart = await _api.getCart();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _mutate(Future<Cart> Function() op) async {
    busy = true;
    notifyListeners();
    try {
      cart = await op();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> add(int productId, int qty) => _mutate(() => _api.addToCart(productId, qty));
  Future<void> setQty(int productId, int qty) => _mutate(() => _api.setQuantity(productId, qty));
  Future<void> remove(int productId) => _mutate(() => _api.removeFromCart(productId));

  Future<Order> checkout(String paymentMethod) async {
    busy = true;
    notifyListeners();
    try {
      final order = await _api.checkout(paymentMethod);
      cart = await _api.getCart();
      return order;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void reset() {
    cart = const Cart();
    notifyListeners();
  }
}
