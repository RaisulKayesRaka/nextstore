import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../core/utils/ui_utils.dart';

class ApplyCouponScreen extends StatefulWidget {
  const ApplyCouponScreen({super.key});

  @override
  State<ApplyCouponScreen> createState() => _ApplyCouponScreenState();
}

class _ApplyCouponScreenState extends State<ApplyCouponScreen> {
  final _ctrl = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isApplying = true);

    try {
      final couponProvider = context.read<CouponProvider>();
      final cart = context.read<CartProvider>();

      final coupon = await couponProvider.getCouponByCode(code);

      if (!mounted) return;

      if (coupon == null) {
        UiUtils.showSnackBar(context, "Invalid Coupon Code", isError: true);
      } else {
        final applied = cart.applyCoupon(coupon);
        if (applied) {
          UiUtils.showSnackBar(context, "Coupon Applied!");
          Navigator.pop(context);
        } else {
          UiUtils.showSnackBar(
            context,
            "Coupon not applicable for this order.",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showSnackBar(context, "Error applying coupon", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply Coupon")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: "Coupon Code",
                hintText: "e.g. SUMMER50",
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isApplying ? null : _applyCoupon,
                child: _isApplying
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : const Text("Apply"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
