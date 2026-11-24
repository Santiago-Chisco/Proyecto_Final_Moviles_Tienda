import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../utils/helpers.dart';
import '../widgets/product_image.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiClient.instance.orders();
      if (mounted) setState(() => _orders = r);
    } catch (e) {
      if (mounted) setState(() => _error = errMsg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      );
    } else if (_orders.isEmpty) {
      body = const Center(child: Text('Aún no tienes pedidos', style: TextStyle(color: Colors.grey)));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _orders.length,
          itemBuilder: (context, i) {
            final o = _orders[i];
            return Card(
              child: ExpansionTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('Pedido #${o.id} · ${formatCop(o.total)}'),
                subtitle: Text('${formatDate(o.createdAt)} · ${o.status}'),
                children: [
                  for (final it in o.items)
                    ListTile(
                      leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 48, height: 48, child: ProductImage(url: it.imageUrl))),
                      title: Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${it.quantity} × ${formatCop(it.price)}'),
                      trailing: Text(formatCop(it.price * it.quantity)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      children: [
                        _row('Subtotal', formatCop(o.subtotal)),
                        _row('IVA', formatCop(o.tax)),
                        _row('Envío', o.shipping == 0 ? 'Gratis' : formatCop(o.shipping)),
                        _row('Total', formatCop(o.total), bold: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Mis pedidos')), body: body);
  }

  Widget _row(String l, String v, {bool bold = false}) {
    final s = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: s), Text(v, style: s)]);
  }
}
