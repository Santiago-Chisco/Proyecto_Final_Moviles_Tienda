import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../utils/helpers.dart';
import '../widgets/product_image.dart';

class CartTab extends StatefulWidget {
  final VoidCallback onGoHome;
  final VoidCallback onOrderPlaced;
  const CartTab({super.key, required this.onGoHome, required this.onOrderPlaced});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  String _paymentMethod = 'Contra entrega';

  Future<void> _run(BuildContext context, Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      if (context.mounted) showMsg(context, errMsg(e), error: true);
    }
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text('Método: $_paymentMethod\nSe simulará el pago de ${formatCop(cart.cart.total)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pagar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final order = await cart.checkout(_paymentMethod);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('¡Compra exitosa!'),
          content: Text('Tu pedido #${order.id} fue registrado por ${formatCop(order.total)} (pago simulado).'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Seguir comprando')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOrderPlaced();
              },
              child: const Text('Ver mis pedidos'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) showMsg(context, errMsg(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartProvider>();
    final cart = provider.cart;

    if (provider.loading && cart.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cart.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 90, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Tu carrito está vacío', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Agrega productos para verlos aquí.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: widget.onGoHome, icon: const Icon(Icons.storefront), label: const Text('Explorar productos')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (provider.busy) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _CartRow(item: cart.items[i], busy: provider.busy, run: (op) => _run(context, op)),
          ),
        ),
        Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text('Método de pago', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  _paymentOption('Contra entrega', 'Pagas cuando recibas tu pedido', Icons.local_shipping_outlined),
                  _paymentOption('Transferencia bancaria', 'Transferencia a cuenta bancaria', Icons.account_balance_outlined),
                  _paymentOption('Tarjeta débito/crédito', 'Pago con tarjeta (simulado)', Icons.credit_card_outlined),
                  const Divider(height: 14),
                  _line('Subtotal', formatCop(cart.subtotal)),
                  _line('IVA (${(cart.taxRate * 100).round()} %)', formatCop(cart.tax)),
                  _line('Envío', cart.shipping == 0 ? 'Gratis' : formatCop(cart.shipping)),
                  if (cart.shipping > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Envío gratis desde ${formatCop(cart.freeShippingFrom)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                  const Divider(),
                  _line('Total', formatCop(cart.total), big: true, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: provider.busy ? null : () => _checkout(context),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.payment),
                      label: const Text('Proceder al pago'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentOption(String value, String subtitle, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      onChanged: (next) => setState(() => _paymentMethod = next!),
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      secondary: Icon(icon, size: 21),
    );
  }

  Widget _line(String label, String value, {bool big = false, Color? color}) {
    final style = TextStyle(fontSize: big ? 20 : 14, fontWeight: big ? FontWeight.bold : FontWeight.normal, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final bool busy;
  final void Function(Future<void> Function()) run;
  const _CartRow({required this.item, required this.busy, required this.run});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 72, height: 72, child: ProductImage(url: item.imageUrl))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(formatCop(item.price), style: const TextStyle(color: Colors.grey)),
                  Row(
                    children: [
                      IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        onPressed: busy || item.quantity <= 1 ? null : () => run(() => cart.setQty(item.productId, item.quantity - 1)),
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      SizedBox(width: 32, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                      IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        onPressed: busy || item.quantity >= 20 ? null : () => run(() => cart.setQty(item.productId, item.quantity + 1)),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                      const Spacer(),
                      Text(formatCop(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: busy ? null : () => run(() => cart.remove(item.productId)),
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
