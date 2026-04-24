import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../core/models/address_model.dart';
import '../widgets/custom_text_field.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _detailsCtrl;
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: widget.address?.name ?? user?.name);
    _phoneCtrl = TextEditingController(
      text: widget.address?.phone ?? user?.phone,
    );
    _detailsCtrl = TextEditingController(text: widget.address?.details);
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AddressProvider>();
      final addr = AddressModel(
        id: widget.address?.id ?? '',
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        details: _detailsCtrl.text.trim(),
        isDefault: _isDefault,
      );

      if (widget.address == null) {
        await provider.addAddress(user.id, addr);
      } else {
        await provider.updateAddress(user.id, addr);
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
        title: Text(widget.address == null ? "Add Address" : "Edit Address"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameCtrl,
                label: "Receiver's Name",
                hint: "e.g. John Doe",
                validator: (v) =>
                    v == null || v.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneCtrl,
                label: "Phone Number",
                hint: "01XXXXXXXXX",
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? "Phone number is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _detailsCtrl,
                label: "Address Details",
                hint: "House, Road, Area, City",
                maxLines: 4,
                minLines: 2,
                validator: (v) => v == null || v.isEmpty
                    ? "Address details are required"
                    : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Set as Default Address",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: const Text("Use this address for future orders"),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  child: _isSaving
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : const Text("SAVE ADDRESS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
