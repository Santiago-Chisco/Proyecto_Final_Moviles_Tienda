import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../utils/helpers.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _adding = false;

  Future<void> _add() async {
    setState(() => _adding = true);
    try {
      await context.read<CartProvider>().add(widget.product.id, _qty);
      if (!mounted) return;
      showMsg(context, 'Agregaste $_qty × ${widget.product.name} al carrito');
    } catch (e) {
      if (mounted) showMsg(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(p.name, overflow: TextOverflow.ellipsis)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              AspectRatio(aspectRatio: 1, child: Hero(tag: 'product-${p.id}', child: ProductImage(url: p.imageUrl))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(label: Text(p.category), visualDensity: VisualDensity.compact),
                    const SizedBox(height: 8),
                    Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(formatCop(p.price), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.primary)),
                    const SizedBox(height: 16),
                    Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(p.description, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton.outlined(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove)),
                        SizedBox(width: 44, child: Text('$_qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton.outlined(onPressed: _qty < 20 ? () => setState(() => _qty++) : null, icon: const Icon(Icons.add)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _adding ? null : _add,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: _adding
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_shopping_cart),
                      label: Text('Agregar al carrito · ${formatCop(p.price * _qty)}'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver a la lista'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
