import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Dummy data for the medicine list
  final List<Map<String, dynamic>> _medicines = [
    {
      'name': 'Paracetamol 500mg',
      'category': 'Tablet',
      'brand': 'Crocin',
      'stock': 450,
      'price': 15.00,
      'expiry': '12/2025',
      'status': 'In Stock',
    },
    {
      'name': 'Amoxicillin 250mg',
      'category': 'Capsule',
      'brand': 'Mox',
      'stock': 120,
      'price': 45.50,
      'expiry': '08/2024',
      'status': 'Low Stock',
    },
    {
      'name': 'Ibuprofen 400mg',
      'category': 'Tablet',
      'brand': 'Brufen',
      'stock': 850,
      'price': 22.00,
      'expiry': '01/2026',
      'status': 'In Stock',
    },
    {
      'name': 'Cetirizine 10mg',
      'category': 'Tablet',
      'brand': 'Zyrtec',
      'stock': 0,
      'price': 18.00,
      'expiry': '05/2025',
      'status': 'Out of Stock',
    },
    {
      'name': 'Azithromycin 500mg',
      'category': 'Tablet',
      'brand': 'Zithromax',
      'stock': 320,
      'price': 110.00,
      'expiry': '11/2025',
      'status': 'In Stock',
    },
  ];

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'In Stock':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'Low Stock':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        break;
      case 'Out of Stock':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.all(32.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        children: [
                          TextSpan(text: 'Medicine '),
                          TextSpan(text: 'Inventory', style: TextStyle(color: Color(0xFF166534))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your medicine stock, expiry, and availability in one place.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Search Bar
                    Container(
                      width: 280,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search inventory by name or brand...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/counter/inventory/upload'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Table Header
                      Container(
                        color: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            SizedBox(width: 40), // For action button
                          ],
                        ),
                      ),
                      
                      // Table Body
                      Expanded(
                        child: ListView.separated(
                          itemCount: _medicines.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (context, index) {
                            final medicine = _medicines[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(medicine['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text(medicine['brand'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 2, child: Text(medicine['category'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      medicine['stock'].toString(),
                                      style: TextStyle(
                                        color: medicine['stock'] == 0 ? const Color(0xFF991B1B) : const Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(flex: 2, child: Text('₹${medicine['price'].toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text(medicine['expiry'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                  Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(medicine['status']))),
                                  const SizedBox(
                                    width: 40,
                                    child: Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
