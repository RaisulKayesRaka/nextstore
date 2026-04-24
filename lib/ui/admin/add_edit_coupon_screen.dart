import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/coupon_provider.dart';
import '../../core/models/coupon_model.dart';
import '../widgets/custom_text_field.dart';

class AddEditCouponScreen extends StatefulWidget {
  final CouponModel? coupon;

  const AddEditCouponScreen({super.key, this.coupon});

  @override
  State<AddEditCouponScreen> createState() => _AddEditCouponScreenState();
}

class _AddEditCouponScreenState extends State<AddEditCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _valCtrl;
  late TextEditingController _minCtrl;
  late String _type;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.coupon?.code);
    _valCtrl = TextEditingController(
      text: widget.coupon?.discountValue.toString(),
    );
    _minCtrl = TextEditingController(
      text: widget.coupon?.minOrderAmount.toString() ?? '0.0',
    );
    _type = widget.coupon?.discountType ?? 'fixed';
    _selectedDate =
        widget.coupon?.expiryDate ??
        DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<CouponProvider>();
      final c = CouponModel(
        id: widget.coupon?.id ?? '',
        code: _codeCtrl.text.trim().toUpperCase(),
        discountType: _type,
        discountValue: double.tryParse(_valCtrl.text) ?? 0.0,
        minOrderAmount: double.tryParse(_minCtrl.text) ?? 0.0,
        expiryDate: _selectedDate,
        isActive: widget.coupon?.isActive ?? true,
      );

      if (widget.coupon == null) {
        await provider.addCoupon(c);
      } else {
        await provider.updateCoupon(c);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coupon == null ? "Add Coupon" : "Edit Coupon"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _codeCtrl,
                label: "Coupon Code",
                hint: "e.g. SUMMER50",
                validator: (v) =>
                    v == null || v.isEmpty ? "Code is required" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Fixed Amount (৳)'),
                  ),
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage (%)'),
                  ),
                ],
                onChanged: (val) => setState(() => _type = val!),
                decoration: const InputDecoration(labelText: "Discount Type"),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _valCtrl,
                label: "Discount Value",
                hint: "e.g. 50",
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? "Value is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _minCtrl,
                label: "Min Order Amount (৳)",
                hint: "e.g. 500",
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? "Minimum amount is required"
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                "Expiry Date",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (pickedDate != null) {
                    if (!context.mounted) return;
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCoupon,
                  child: _isSaving
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : const Text("SAVE COUPON"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
