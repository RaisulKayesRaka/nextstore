import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/empty_state.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategoryId;

  const ProductsScreen({super.key, this.initialCategoryId});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            final categories = provider.enabledCategories;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: RadioGroup<String?>(
                      groupValue: _selectedCategoryId,
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                        Navigator.pop(context);
                      },
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          const RadioListTile<String?>(
                            title: Text("All Products"),
                            value: null,
                          ),
                          ...categories.map(
                            (c) => RadioListTile<String?>(
                              title: Text(c.name),
                              value: c.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortBottomSheet() {
    final provider = context.read<ProductProvider>();
    final options = ['Newest', 'Price: Low to High', 'Price: High to Low'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  "Sort By",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              RadioGroup<String>(
                groupValue: provider.currentSort,
                onChanged: (val) {
                  if (val != null) {
                    provider.sortProducts(val);
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options
                      .map(
                        (opt) =>
                            RadioListTile<String>(title: Text(opt), value: opt),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton({
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          backgroundColor: isActive
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: isActive
              ? colorScheme.primary
              : colorScheme.onSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(Icons.check, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !_isSearching,
        titleSpacing: _isSearching ? 0 : null,
        title: _isSearching
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchCtrl.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Search products...",
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                  ],
                ),
              )
            : const Text("Products"),
        actions: _isSearching
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: Consumer2<CategoryProvider, ProductProvider>(
              builder: (context, catProvider, prodProvider, _) {
                String catLabel = "All Categories";
                if (_selectedCategoryId != null) {
                  final cat = catProvider.categories.firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => catProvider.categories.first,
                  );
                  catLabel = cat.name;
                }

                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: [
                    _buildFilterButton(
                      label: catLabel,
                      onTap: _showCategoryBottomSheet,
                      isActive:
                          true, // Always show check for current category selection
                    ),
                    _buildFilterButton(
                      label: "Sort: ${prodProvider.currentSort}",
                      onTap: _showSortBottomSheet,
                      isActive:
                          true, // Always show check for current sort selection
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, prodProvider, child) {
                if (prodProvider.isLoading && prodProvider.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                var list = prodProvider.searchProducts(_searchQuery);
                if (_selectedCategoryId != null) {
                  list = list
                      .where((p) => p.categoryId == _selectedCategoryId)
                      .toList();
                }

                return RefreshIndicator(
                  onRefresh: () => prodProvider.fetchProducts(),
                  child: list.isEmpty
                      ? _searchQuery.isNotEmpty
                            ? EmptyState(
                                icon: Icons.search_off,
                                title: "No Results Found",
                                message:
                                    "We couldn't find any products matching '$_searchQuery'",
                              )
                            : EmptyState(
                                title: "No Products",
                                message:
                                    "There are no products available in this category.",
                              )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            return ProductCard(product: list[index]);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
