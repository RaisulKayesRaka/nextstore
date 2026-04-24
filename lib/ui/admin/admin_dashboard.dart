import 'package:flutter/material.dart';

import 'manage_categories_screen.dart';
import 'manage_products_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_coupons_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(context, "Categories", Icons.category, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
            );
          }),
          _buildDashboardCard(context, "Products", Icons.inventory_2, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
            );
          }),
          _buildDashboardCard(context, "Orders", Icons.shopping_bag, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
            );
          }),
          _buildDashboardCard(context, "Coupons", Icons.local_offer, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageCouponsScreen()),
            );
          }),
        ],
      ),
    );
  }
}
