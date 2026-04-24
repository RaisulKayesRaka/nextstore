import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../core/models/order_model.dart';
import '../../core/models/address_model.dart';
import '../../core/utils/ui_utils.dart';
import '../../providers/product_provider.dart';
import 'home_screen.dart';
import 'add_edit_address_screen.dart';
import 'apply_coupon_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<AddressProvider>().fetchAddresses(user.id).then((_) {
          if (!mounted) return;
          final addrs = context.read<AddressProvider>().addresses;
          if (addrs.isNotEmpty) {
            setState(() {
              _selectedAddress = addrs.firstWhere(
                (a) => a.isDefault,
                orElse: () => addrs.first,
              );
            });
          }
        });
      }
    });
  }

  void _placeOrder() async {
    if (_selectedAddress == null) {
      UiUtils.showSnackBar(
        context,
        "Please select or add a delivery address.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final items = cart.items
        .map((e) => OrderItem(product: e.product, quantity: e.quantity))
        .toList();

    final order = OrderModel(
      id: '',
      userId: auth.currentUser!.id,
      shippingAddress: _selectedAddress!,
      items: items,
      subTotal: cart.subTotal,
      discount: cart.discountAmount,
      deliveryCharge: cart.deliveryCharge,
      totalAmount: cart.finalTotal,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      final success = await orderProvider.createOrder(order);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        cart.clearCart();
        UiUtils.showSnackBar(context, "Order placed successfully! (COD)");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        UiUtils.showSnackBar(
          context,
          "Failed to place order. Please check item availability.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      UiUtils.showSnackBar(
        context,
        e.toString().replaceAll("Exception: ", ""),
        isError: true,
      );
    }
  }

  Future<void> _refresh() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await Future.wait([
        context.read<AddressProvider>().fetchAddresses(user.id),
        context.read<ProductProvider>().fetchProducts(),
        context.read<CartProvider>().refresh(),
      ]);

      if (!mounted) return;

      final addrs = context.read<AddressProvider>().addresses;
      if (addrs.isNotEmpty) {
        if (_selectedAddress == null ||
            !addrs.any((a) => a.id == _selectedAddress!.id)) {
          setState(() {
            _selectedAddress = addrs.firstWhere(
              (a) => a.isDefault,
              orElse: () => addrs.first,
            );
          });
        }
      } else {
        setState(() => _selectedAddress = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addrProvider = context.watch<AddressProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Delivery Address",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditAddressScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("New"),
                  ),
                ],
              ),
              if (addrProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (addrProvider.addresses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No addresses found. Add one to proceed.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...addrProvider.addresses.map((a) {
                  final isSelected = _selectedAddress?.id == a.id;
                  return InkWell(
                    onTap: () => setState(() => _selectedAddress = a),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.05)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  a.details,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  a.phone,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),
              Text("Coupon", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: cart.appliedCoupon == null
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ApplyCouponScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Apply Coupon",
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      color: colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Coupon '${cart.appliedCoupon!.code}' applied!",
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              onPressed: () => cart.removeCoupon(),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                "Your Items",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cart.items.length,
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item.product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${item.quantity} x ${UiUtils.formatCurrency(item.product.price)}",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          UiUtils.formatCurrency(
                            item.product.price * item.quantity,
                          ),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              Text(
                "Order Summary",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal"),
                        Text(
                          UiUtils.formatCurrency(cart.subTotal),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (cart.appliedCoupon != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Discount",
                            style: TextStyle(color: colorScheme.primary),
                          ),
                          Text(
                            "-${UiUtils.formatCurrency(cart.discountAmount)}",
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Delivery Charge"),
                        Text(
                          UiUtils.formatCurrency(cart.deliveryCharge),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          UiUtils.formatCurrency(cart.finalTotal),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                "Payment Method",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary, width: 2),
                  color: colorScheme.primary.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Icon(Icons.money, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Cash on Delivery (COD)",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Icon(Icons.check_circle, color: colorScheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              child: _isLoading
                  ? CircularProgressIndicator(color: colorScheme.onPrimary)
                  : Text(
                      "Place Order ${UiUtils.formatCurrency(cart.finalTotal)}",
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
