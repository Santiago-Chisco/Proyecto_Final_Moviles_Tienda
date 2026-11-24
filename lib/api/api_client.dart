import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final Map<String, String> fields;
  ApiException(this.message, {this.status, this.fields = const {}});
  @override
  String toString() => message;
}

/// Cliente HTTP único: TODOS los datos de la app entran y salen por la API REST.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? token;
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$apiBaseUrl/api$path');
    return (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: query);
  }

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final req = http.Request(method, _uri(path, query));
    req.headers['Content-Type'] = 'application/json';
    req.headers['Accept'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      // 60 s: el plan gratuito de Render tarda ~50 s en "despertar".
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    dynamic data;
    if (res.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode >= 400) {
      final Map map = data is Map ? data : const {};
      final fields = <String, String>{};
      if (map['fields'] is Map) {
        (map['fields'] as Map).forEach((k, v) => fields[k.toString()] = v.toString());
      }
      if (res.statusCode == 401 && token != null) onUnauthorized?.call();
      throw ApiException((map['error'] ?? 'Error ${res.statusCode}').toString(), status: res.statusCode, fields: fields);
    }
    return data;
  }

  Map<String, dynamic> _map(dynamic d) => d as Map<String, dynamic>;
  List<dynamic> _list(dynamic d) => d as List<dynamic>;

  // ---- auth ----
  Future<({String token, AppUser user})> login(String identifier, String password) async {
    final d = _map(await _send('POST', '/auth/login', body: {'identifier': identifier, 'password': password}));
    return (token: d['token'] as String, user: AppUser.fromJson(_map(d['user'])));
  }

  Future<void> register({required String firstName, required String lastName, required String username, required String email, required String password}) async {
    await _send('POST', '/auth/register', body: {
      'firstName': firstName, 'lastName': lastName, 'username': username, 'email': email, 'password': password,
    });
  }

  Future<bool> usernameAvailable(String username) async {
    final d = _map(await _send('GET', '/auth/check-username', query: {'username': username}));
    return d['available'] == true;
  }

  Future<AppUser> me() async => AppUser.fromJson(_map(_map(await _send('GET', '/auth/me'))['user']));
  Future<void> logout() async {
    await _send('POST', '/auth/logout');
  }

  /// Devuelve el mensaje y, si el servidor no envía correo, un código de demostración.
  Future<({String message, String? devToken})> forgot(String email) async {
    final d = _map(await _send('POST', '/auth/forgot', body: {'email': email}));
    return (message: d['message'] as String, devToken: d['devToken'] as String?);
  }

  Future<String> reset(String token, String password) async {
    final d = _map(await _send('POST', '/auth/reset', body: {'token': token, 'password': password}));
    return d['message'] as String;
  }

  // ---- perfil ----
  Future<AppUser> updateProfile({required String firstName, required String lastName, required String username}) async {
    final d = _map(await _send('PUT', '/users/me', body: {'firstName': firstName, 'lastName': lastName, 'username': username}));
    return AppUser.fromJson(_map(d['user']));
  }

  Future<void> changePassword(String current, String next) async {
    await _send('PUT', '/users/me/password', body: {'currentPassword': current, 'newPassword': next});
  }

  // ---- catálogo ----
  Future<List<BannerItem>> banners() async => _list(await _send('GET', '/banners')).map((e) => BannerItem.fromJson(_map(e))).toList();
  Future<List<Category>> categories() async => _list(await _send('GET', '/categories')).map((e) => Category.fromJson(_map(e))).toList();

  Future<List<Product>> products({String search = '', String category = ''}) async {
    final q = <String, String>{};
    if (search.isNotEmpty) q['search'] = search;
    if (category.isNotEmpty && category != 'Todos') q['category'] = category;
    return _list(await _send('GET', '/products', query: q)).map((e) => Product.fromJson(_map(e))).toList();
  }

  // ---- carrito ----
  Future<Cart> getCart() async => Cart.fromJson(_map(await _send('GET', '/cart')));
  Future<Cart> addToCart(int productId, int quantity) async =>
      Cart.fromJson(_map(await _send('POST', '/cart', body: {'productId': productId, 'quantity': quantity})));
  Future<Cart> setQuantity(int productId, int quantity) async =>
      Cart.fromJson(_map(await _send('PUT', '/cart/$productId', body: {'quantity': quantity})));
  Future<Cart> removeFromCart(int productId) async => Cart.fromJson(_map(await _send('DELETE', '/cart/$productId')));

  // ---- pedidos ----
  Future<Order> checkout(String paymentMethod) async => Order.fromJson(_map(await _send('POST', '/orders', body: {'paymentMethod': paymentMethod})));
  Future<List<Order>> orders() async => _list(await _send('GET', '/orders')).map((e) => Order.fromJson(_map(e))).toList();
}
