import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/banner_provider.dart';
import '../../core/models/banner_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  void _showAddBannerDialog(BuildContext context) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Banner"),
        content: CustomTextField(
          controller: urlCtrl,
          label: "Image URL",
          hint: "https://example.com/banner.jpg",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlCtrl.text.isNotEmpty) {
                context.read<BannerProvider>().addBanner(
                  BannerModel(id: '', imageUrl: urlCtrl.text.trim()),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String bannerId) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Banner"),
        content: Text(
          "Are you sure you want to delete banner '${bannerId.toUpperCase().substring(0, 8)}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Banners")),
      body: Consumer<BannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.banners.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchBanners(),
            child: provider.banners.isEmpty
                ? EmptyState(
                    icon: Icons.image_outlined,
                    title: "No Banners",
                    message:
                        "You haven't added any banners yet. Use the + button to add one.",
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.banners.length,
                    itemBuilder: (context, index) {
                      final banner = provider.banners[index];
                      return Dismissible(
                        key: Key(banner.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) =>
                            _confirmDelete(context, banner.id),
                        onDismissed: (direction) =>
                            provider.deleteBanner(banner.id),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: CachedNetworkImage(
                                  imageUrl: banner.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                              ListTile(
                                title: const Text(
                                  "Banner Image",
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await _confirmDelete(
                                      context,
                                      banner.id,
                                    );
                                    if (confirmed == true) {
                                      provider.deleteBanner(banner.id);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBannerDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
