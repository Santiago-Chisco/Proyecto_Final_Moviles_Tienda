import '../config.dart';

class AppUser {
  final int id;
  final String firstName, lastName, username, email;
  AppUser({required this.id, required this.firstName, required this.lastName, required this.username, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        username: j['username'] as String,
        email: j['email'] as String,
      );

  String get fullName => '$firstName $lastName';
  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return (a + b).toUpperCase();
  }
}

class Product {
  final int id, price, stock;
  final String name, description, category, imageUrl;
  Product({required this.id, required this.price, required this.stock, required this.name, required this.description, required this.category, required this.imageUrl});

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        price: j['price'] as int,
        stock: (j['stock'] ?? 0) as int,
        name: j['name'] as String,
        description: j['description'] as String,
        category: j['category'] as String,
        imageUrl: resolveUrl(j['imageUrl'] as String),
      );
}

class Category {
  final int id;
  final String name;
  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) => Category(id: j['id'] as int, name: j['name'] as String);
}

class BannerItem {
  final int id;
  final String title, subtitle, imageUrl;
  BannerItem({required this.id, required this.title, required this.subtitle, required this.imageUrl});
  factory BannerItem.fromJson(Map<String, dynamic> j) => BannerItem(
        id: j['id'] as int,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        imageUrl: resolveUrl(j['imageUrl'] as String),
      );
}

class CartItem {
  final int productId, price, quantity, lineTotal;
  final String name, imageUrl;
  CartItem({required this.productId, required this.price, required this.quantity, required this.lineTotal, required this.name, required this.imageUrl});
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productId: j['productId'] as int,
        price: j['price'] as int,
        quantity: j['quantity'] as int,
        lineTotal: j['lineTotal'] as int,
        name: j['name'] as String,
        imageUrl: resolveUrl(j['imageUrl'] as String),
      );
}

class Cart {
  final List<CartItem> items;
  final int itemCount, subtotal, tax, shipping, total, freeShippingFrom;
  final double taxRate;
  const Cart({this.items = const [], this.itemCount = 0, this.subtotal = 0, this.tax = 0, this.shipping = 0, this.total = 0, this.freeShippingFrom = 0, this.taxRate = 0.19});

  factory Cart.fromJson(Map<String, dynamic> j) => Cart(
        items: (j['items'] as List).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
        itemCount: j['itemCount'] as int,
        subtotal: j['subtotal'] as int,
        tax: j['tax'] as int,
        shipping: j['shipping'] as int,
        total: j['total'] as int,
        freeShippingFrom: j['freeShippingFrom'] as int,
        taxRate: (j['taxRate'] as num).toDouble(),
      );
}

class OrderItem {
  final String name, imageUrl;
  final int price, quantity;
  OrderItem({required this.name, required this.imageUrl, required this.price, required this.quantity});
  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: j['name'] as String,
        imageUrl: resolveUrl(j['imageUrl'] as String),
        price: j['price'] as int,
        quantity: j['quantity'] as int,
      );
}

class Order {
  final int id, subtotal, tax, shipping, total;
  final String status, createdAt;
  final List<OrderItem> items;
  Order({required this.id, required this.subtotal, required this.tax, required this.shipping, required this.total, required this.status, required this.createdAt, required this.items});
  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        subtotal: j['subtotal'] as int,
        tax: j['tax'] as int,
        shipping: j['shipping'] as int,
        total: j['total'] as int,
        status: j['status'] as String,
        createdAt: j['createdAt'] as String,
        items: (j['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
