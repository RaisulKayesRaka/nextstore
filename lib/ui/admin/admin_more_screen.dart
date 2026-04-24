import 'package:flutter/material.dart';
import 'manage_categories_screen.dart';
import 'manage_coupons_screen.dart';
import 'manage_banners_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("More Options")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text("Manage Categories"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageCategoriesScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text("Manage Coupons"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageCouponsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.view_carousel),
            title: const Text("Manage Banners"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageBannersScreen()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
