import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../core/models/category_model.dart';
import '../widgets/custom_text_field.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _imageCtrl;
  bool _isSaving = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name);
    _imageCtrl = TextEditingController(text: widget.category?.imageUrl);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_isSaving || _isNavigating) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<CategoryProvider>();
      if (widget.category == null) {
        final cat = CategoryModel(
          id: '',
          name: _nameCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          isEnabled: true,
        );
        final newId = await provider.addCategory(cat);
        if (mounted) {
          if (newId != null) {
            _isNavigating = true;
            Navigator.pop(context, newId);
          } else {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to add category")),
            );
          }
        }
      } else {
        final cat = CategoryModel(
          id: widget.category!.id,
          name: _nameCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          isEnabled: widget.category!.isEnabled,
        );
        final success = await provider.updateCategory(cat);
        if (mounted) {
          if (success) {
            _isNavigating = true;
            Navigator.pop(context, cat.id);
          } else {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to update category")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? "Add Category" : "Edit Category"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameCtrl,
                label: "Category Name",
                hint: "e.g. Electronics",
                validator: (v) =>
                    v == null || v.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _imageCtrl,
                label: "Image URL",
                hint: "https://example.com/category.jpg",
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCategory,
                  child: _isSaving
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : Text(
                          widget.category == null
                              ? "SAVE CATEGORY"
                              : "UPDATE CATEGORY",
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
