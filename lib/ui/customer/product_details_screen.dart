import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../../core/utils/ui_utils.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  late List<String> _allImages;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _allImages = [
      widget.product.imageUrl,
      ...widget.product.images,
    ].where((img) => img.trim().isNotEmpty).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();

    final product =
        productProvider.products
            .where((p) => p.id == widget.product.id)
            .firstOrNull ??
        widget.product;

    final categoryText =
        catProvider.categories
            .where((c) => c.id == product.categoryId)
            .firstOrNull
            ?.name ??
        "Uncategorized";
    final colorScheme = Theme.of(context).colorScheme;

    final cartProvider = context.watch<CartProvider>();
    final cartItem = cartProvider.items
        .where((item) => item.product.id == product.id)
        .firstOrNull;
    final inCartQuantity = cartItem?.quantity ?? 0;
    final availableToAdd = product.stockQuantity - inCartQuantity;

    return Scaffold(
      appBar: AppBar(title: const Text("Product Details")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Image
                  SizedBox(
                    height: 350,
                    child: _allImages.isEmpty
                        ? Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 100,
                                color: colorScheme.outline,
                              ),
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _allImages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _selectedImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Hero(
                                tag: index == 0
                                    ? 'product_image_${product.id}'
                                    : 'product_image_${product.id}_$index',
                                child: CachedNetworkImage(
                                  imageUrl: _allImages[index],
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 60,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  if (_allImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _allImages.length,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedImageIndex == index;
                            return GestureDetector(
                              onTap: () {
                                _pageController.jumpToPage(index);
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: _allImages[index],
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryText.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          UiUtils.formatCurrency(product.price),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.stockQuantity > 0
                              ? "In Stock: ${product.stockQuantity}${inCartQuantity > 0 ? ' ($inCartQuantity in cart)' : ''}"
                              : "Out of Stock",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: product.stockQuantity > 0
                                    ? Colors.green
                                    : colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        Text(
                          "Description",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        "$_quantity",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: _quantity < availableToAdd
                            ? () => setState(() => _quantity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: availableToAdd > 0
                            ? () {
                                context.read<CartProvider>().addToCart(
                                  product,
                                  _quantity,
                                );
                                UiUtils.showSnackBar(context, "Added to cart!");
                                Navigator.pop(context);
                              }
                            : null,
                        child: Text(
                          availableToAdd > 0
                              ? "ADD TO CART"
                              : (product.stockQuantity > 0
                                    ? "MAX IN CART"
                                    : "OUT OF STOCK"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
