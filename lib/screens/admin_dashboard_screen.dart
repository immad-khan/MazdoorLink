import 'package:flutter/material.dart';
import '../app_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Same background as admin login
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B5E),
        elevation: 0,
        title: Text(
          isUrdu ? 'ایڈمن ڈیش بورڈ' : 'Admin Dashboard',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/'); // Return to welcome screen
            },
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Stats Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF006B5E), Color(0xFF0D9488)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu ? 'پلیٹ فارم کا جائزہ' : 'Platform Overview',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUrdu ? 'خوش آمدید، ایڈمن' : 'Welcome, System Admin',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('124', isUrdu ? 'نئے ورکرز' : 'New Workers'),
                      _buildStatColumn('18', isUrdu ? 'شکایات' : 'Complaints'),
                      _buildStatColumn('Rs 45k', isUrdu ? 'ریفنڈز' : 'Refunds'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isUrdu ? 'مینجمنٹ آپشنز' : 'Management Options',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            
            // Options Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.how_to_reg,
                  title: isUrdu ? 'ورکر کی رجسٹریشن' : 'Worker Registrations',
                  subtitle: isUrdu ? 'منظور یا مسترد کریں' : 'Approve or Reject',
                  color: Colors.blue.shade600,
                ),
                _buildActionCard(
                  context,
                  icon: Icons.report_problem_outlined,
                  title: isUrdu ? 'شکایات' : 'Complaints',
                  subtitle: isUrdu ? 'صارفین کے مسائل' : 'View User Issues',
                  color: Colors.red.shade500,
                ),
                _buildActionCard(
                  context,
                  icon: Icons.broken_image_outlined,
                  title: isUrdu ? 'نقصان کے دعوے' : 'Damage Claims',
                  subtitle: isUrdu ? 'جائزہ اور منظوری' : 'Review & Approve',
                  color: Colors.orange.shade600,
                ),
                _buildActionCard(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: isUrdu ? 'سیکیورٹی ڈپازٹس' : 'Security Deposits',
                  subtitle: isUrdu ? 'کٹوتی اور ریفنڈز' : 'Deduct or Refund',
                  color: Colors.green.shade600,
                ),
                _buildActionCard(
                  context,
                  icon: Icons.block,
                  title: isUrdu ? 'صارف کا انتظام' : 'User Management',
                  subtitle: isUrdu ? 'معطل یا بین کریں' : 'Suspend or Ban',
                  color: Colors.deepPurple.shade500,
                ),
                _buildActionCard(
                  context,
                  icon: Icons.dashboard_customize_outlined,
                  title: isUrdu ? 'تفصیلی ڈیش بورڈ' : 'Platform Stats',
                  subtitle: isUrdu ? 'رپورٹس دیکھیں' : 'View Analytics',
                  color: Colors.teal.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color}) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title...')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
