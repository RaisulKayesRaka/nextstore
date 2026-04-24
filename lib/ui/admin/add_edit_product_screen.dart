import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/models/product_model.dart';
import '../widgets/custom_text_field.dart';
import 'add_edit_category_screen.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _imageCtrl;
  final List<TextEditingController> _additionalImageCtrls = [];
  String? _selectedCat;
  bool _isFeat = false;
  bool _isSaving = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name);
    _descCtrl = TextEditingController(text: widget.product?.description);
    _priceCtrl = TextEditingController(text: widget.product?.price.toString());
    _stockCtrl = TextEditingController(
      text: (widget.product?.stockQuantity ?? 0).toString(),
    );
    _imageCtrl = TextEditingController(text: widget.product?.imageUrl);
    _isFeat = widget.product?.isFeatured ?? false;
    _selectedCat = widget.product?.categoryId;

    if (widget.product?.images != null) {
      for (var url in widget.product!.images) {
        _additionalImageCtrls.add(TextEditingController(text: url));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedCat == null) {
        final categories = context.read<CategoryProvider>().categories;
        if (categories.isNotEmpty) {
          setState(() {
            _selectedCat = categories.first.id;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageCtrl.dispose();
    for (var ctrl in _additionalImageCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _addExtraImageField() {
    setState(() {
      _additionalImageCtrls.add(TextEditingController());
    });
  }

  void _removeExtraImageField(int index) {
    setState(() {
      _additionalImageCtrls[index].dispose();
      _additionalImageCtrls.removeAt(index);
    });
  }

  Future<void> _addNewCategory() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()),
    );

    if (mounted) {
      setState(() {
        _isNavigating = false;
        if (result != null) {
          _selectedCat = result;
        }
      });
    }
  }

  void _showCategoryModal() {
    final categories = context.read<CategoryProvider>().categories;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Category",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _addNewCategory();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: RadioGroup<String>(
                  groupValue: _selectedCat,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCat = val);
                      Navigator.pop(context);
                    }
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return RadioListTile<String>(
                        title: Text(cat.name),
                        value: cat.id,
                        secondary: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: cat.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.category, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCat == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ProductProvider>();
      final price = double.tryParse(_priceCtrl.text) ?? 0.0;
      final stock = int.tryParse(_stockCtrl.text) ?? 0;
      final additionalImages = _additionalImageCtrls
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (widget.product == null) {
        final p = ProductModel(
          id: '',
          name: _nameCtrl.text,
          description: _descCtrl.text,
          price: price,
          categoryId: _selectedCat!,
          imageUrl: _imageCtrl.text,
          images: additionalImages,
          isFeatured: _isFeat,
          stockQuantity: stock,
          createdAt: DateTime.now(),
        );
        await provider.addProduct(p);
      } else {
        final p = widget.product!.copyWith(
          name: _nameCtrl.text,
          description: _descCtrl.text,
          price: price,
          categoryId: _selectedCat!,
          imageUrl: _imageCtrl.text,
          images: additionalImages,
          isFeatured: _isFeat,
          stockQuantity: stock,
        );
        await provider.updateProduct(p);
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
    final categories = context.watch<CategoryProvider>().categories;
    final selectedCategoryName = categories.any((c) => c.id == _selectedCat)
        ? categories.firstWhere((c) => c.id == _selectedCat).name
        : "Select Category";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? "Add Product" : "Edit Product"),
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
                label: "Product Name",
                hint: "e.g. Wireless Headphones",
                validator: (v) =>
                    v == null || v.isEmpty ? "Product name is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descCtrl,
                label: "Description",
                hint: "Provide detailed product description",
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceCtrl,
                label: "Price (৳)",
                hint: "0.0",
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? "Price is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _stockCtrl,
                label: "Stock Quantity",
                hint: "e.g. 50",
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? "Stock quantity is required"
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                "Category",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showCategoryModal,
                borderRadius: BorderRadius.circular(12),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedCategoryName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _imageCtrl,
                label: "Main Image URL",
                hint: "https://example.com/main.jpg",
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Additional Images",
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: _addExtraImageField,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add More"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_additionalImageCtrls.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _additionalImageCtrls[index],
                          decoration: InputDecoration(
                            labelText: "Extra image URL ${index + 1}",
                            hintText: "https://example.com/image.jpg",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _removeExtraImageField(index),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Featured Product",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: const Text("Display on home featured section"),
                value: _isFeat,
                onChanged: (val) => setState(() => _isFeat = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : Text(
                          widget.product == null
                              ? "SAVE PRODUCT"
                              : "UPDATE PRODUCT",
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
